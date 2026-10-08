# How ZENO counts steps

A WHOOP 4.0 sends no step count over Bluetooth that anyone has mapped, so ZENO's steps come from the phone side
(Apple Health, then the iPhone's own pedometer) with the band's motion filling in. This page describes the
hour-by-hour merge ZENO adds on top of NOOP's day-level resolver, and the tools for checking it on real data.

## The day-level resolver (from NOOP)

`StepsResolver` picks one source per day: Apple Health, then the iPhone pedometer, then a strap step counter
(WHOOP 5.0/MG only), then the strap's motion estimate. Any count above zero wins. On its own that drops every step
walked while the phone stayed home: a day the phone counted anything shows only the phone's number.

## The hour-by-hour merge (ZENO)

`StepsHourMerge` (StrandAnalytics) makes the choice per clock hour on days Apple Health or the iPhone counted:

- **The band's estimate per hour** is `k × motion`, where motion is the day's gravity fold split by clock hour
  (each sample-to-sample change goes to the hour of the later sample, so a day's hours sum to
  `StepsEstimateEngine.dayMotionIntensity`). Time asleep and time in cycling, strength, rowing or swimming
  workouts contributes nothing. No hour goes above 9,000 steps.
- **`k` is learned from carried hours**: the phone counted at least 300 steps, the band banked at least half its
  usual rows for an hour, and the wearer was awake and not in a no-footfall workout. It is the motion-weighted
  median of `steps / motion`, needs 24 such hours, and a manual coefficient (Settings) still wins. The day-level
  fit mixed in the hours the phone sat at home, which pulled it low.
- **The rule**: an hour takes the band's estimate only when it is at least 150 steps and at least 50% above the
  phone's count for that hour (the larger of Apple Health's and the iPhone's). Otherwise the phone's count stands.
  Only hours the phone side has finished counting are eligible: those ending at least an hour before the later of
  the iPhone's banked watermark and Apple Health's last hourly import.
- **The day** keeps its source and gains `bandSteps`, the band's additions (`ResolvedStepDay.bandSteps`). Every
  steps surface resolves through `StepsResolver`, so Home, the Steps card and screen, Trends, Explore and the
  Pulse screens all show the same total. A day the phone counted nothing takes the sum of its band hours as its
  estimate once the hourly fit exists.

Where it lives:

| Part | Where |
|---|---|
| Merge rule, hourly split, calibration, estimate | `Packages/StrandAnalytics/.../StepsHourMerge.swift` |
| Per-day reuse of the hourly split | `StepsHourMotionCache.swift` (keyed like `StepsMotionCache`) |
| Analysis pass: fit, band hours to `appleStepHour` under the computed id | `Strand/Data/IntelligenceEngine+BandStepHours.swift` |
| Read side: per-day fill, band hours for the chart | `Strand/Data/Steps/StepsRepository.swift` |
| Settled-hours watermark from Apple Health | `StrandiOS/Health/HealthKitBridge.swift` |
| Screens: dashed hour tops, "+ band" badge, the switch | `Strand/Screens/Steps/`, `StepsCalibrationSheet` in `SettingsView.swift` |

The switch is Settings › Profile › Steps estimate › Hours your phone missed (`steps.bandFill`, on by default).
Android keeps the day-level resolver.

## Checking it on your own data

- [Tools/zeno/steps-replay](../../Tools/zeno/steps-replay) replays the merge over a copy of the app's database:
  how densely the band stores motion, the calibration, what each day would gain, and a hide-the-phone test.
- [Tools/zeno/steps-probe](../../Tools/zeno/steps-probe) looks for the band's own step counter in the raw frames
  of a sync after a counted walk.

## Known limits

- Hand movement with the phone set down (cooking, driving) can look like walking to the band, so an hour of it
  can gain up to a few hundred steps. The 150-step margin keeps most of it out; the replay shows how much remains.
- The estimate inherits the iPhone's own undercount, since that is what it is calibrated against.
- If the band stores motion in bursts rather than every second, the hourly estimate is rough; the replay's first
  report shows which.
