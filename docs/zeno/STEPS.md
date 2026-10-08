# How ZENO counts steps

A WHOOP 4.0 sends no step count over Bluetooth that anyone has mapped, so ZENO's steps come from the phone side
(Apple Health, then the iPhone's own pedometer) with the strap filling the hours the phone missed. This page
describes that hour-by-hour fill, which ZENO adds on top of NOOP's day-level resolver, and the tools for checking
it on real data.

## The day-level resolver (from NOOP)

`StepsResolver` picks one source per day: Apple Health, then the iPhone pedometer, then a strap step counter
(WHOOP 5.0/MG only), then the strap's motion estimate. Any count above zero wins. On its own that drops every step
walked while the phone stayed home: a day the phone counted anything shows only the phone's number.

## The hour-by-hour fill (ZENO)

`StepsHourMerge` (StrandAnalytics) makes the choice per clock hour on days Apple Health or the iPhone counted.

**Walking minutes, not motion volume.** A WHOOP 4.0 banks one heavily smoothed gravity vector a second, plus
heart rate. The first version summed the vector's changes per hour, like NOOP's day estimate. On the first real
wearer's data that failed badly: an hour of typing and phone use summed to as much movement as an hour that walked
1,700 steps, so it added 5,000-11,000 steps a day that were never walked. Walking looks different minute by
minute, so the strap's estimate now counts walking minutes:

- A minute walked when at least 95% of its second-to-second changes exceed 0.02 g, their median is at least
  0.03 g, at least 40 changes were recorded, and its mean heart rate is at least 15 bpm above the day's resting
  level (the 10th percentile of the day's heart rate). Minutes without heart rate are judged on movement alone.
- Only runs of two or more walking minutes count; a single busy minute of arm movement can look like walking.
- The estimate for an hour is its walking minutes times the wearer's pace, steps per walking minute. Time asleep
  and time in cycling, strength, rowing or swimming workouts contribute nothing. No hour goes above 9,000 steps.

**The pace is learned from carried hours**: the phone counted at least 300 steps, the strap banked at least half
its usual rows for the hour and saw at least 3 walking minutes, and the wearer was awake and not in a no-footfall
workout. It is the walking-minute-weighted median of `steps / walking minutes`, needs 24 such hours, and must come
out between 50 and 200 steps a minute or nothing is filled. On the first wearer it was 101, an ordinary walking
cadence.

**The rule**: an hour takes the strap's estimate only when it is at least 150 steps and at least 50% above the
phone's count for that hour (the larger of Apple Health's and the iPhone's). Otherwise the phone's count stands.
Only hours the phone side has finished counting are eligible: those ending at least an hour before the later of
the iPhone's banked watermark and Apple Health's last hourly import.

**The day** keeps its source and gains `bandSteps`, the strap's additions (`ResolvedStepDay.bandSteps`). Every
steps surface resolves through `StepsResolver`, so Home, the Steps card and screen, Trends, Explore and the Pulse
screens all show the same total. A day the phone counted nothing takes the sum of its strap hours as its estimate
once the pace is known, unless a manual coefficient is set in Settings (that one is in the old motion units).

Where it lives:

| Part | Where |
|---|---|
| Walking detector, pace, estimate, merge rule | `Packages/StrandAnalytics/.../StepsHourMerge.swift` |
| Per-day reuse of the hourly walking | `StepsHourWalkCache.swift` (keyed like `StepsMotionCache`) |
| Analysis pass: pace, strap hours to `appleStepHour` under the computed id | `Strand/Data/IntelligenceEngine+BandStepHours.swift` |
| Read side: per-day fill, strap hours for the chart | `Strand/Data/Steps/StepsRepository.swift` |
| Settled-hours watermark from Apple Health | `StrandiOS/Health/HealthKitBridge.swift` |
| Screens: dashed hour tops, "+ strap" badge, the switch | `Strand/Screens/Steps/`, `StepsCalibrationSheet` in `SettingsView.swift` |

The switch is Settings › Profile › Steps estimate › Hours your phone missed (`steps.bandFill`, on by default).
Android keeps the day-level resolver.

## How well it does

On the first wearer's data (10 days of strap history, 26 carried hours, 8 October 2026), hiding the phone's count
for each carried hour in turn and letting the strap fill it with a pace learned without that day put the day's
total within a median 2% (lean +3%, 85% of tests within 10%), against 21% short with no fill. The strap's estimate
for those hours on their own was within a median 15%. It added a median of about 1,900 steps a day.

That test can only score hours the phone was carried. Whether the strap's extra walking in other hours is real
cannot be checked from the data alone; a counted walk with the phone at home can (see steps-probe).

## Checking it on your own data

- [Tools/zeno/steps-replay](../../Tools/zeno/steps-replay) replays the fill over a copy of the app's database:
  how densely the strap stores motion, the pace, what each day gains, and the hide-the-phone test.
- [Tools/zeno/steps-probe](../../Tools/zeno/steps-probe) looks for the strap's own step counter in the raw frames
  of a sync after a counted walk.

## Known limits

- Walking with the arm still (pushing a trolley, hands in pockets) barely shows in the strap's motion, so those
  hours are not filled; the phone covers them when carried.
- Sustained arm movement with a raised heart rate (some housework, a gym session that was not logged) can pass for
  walking. Logging the workout keeps it out.
- The pace inherits the iPhone's own counting, since that is what it is learned from.
