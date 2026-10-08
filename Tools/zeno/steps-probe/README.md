# steps-probe

Looks for a WHOOP 4.0's own step counter in the raw frames ZENO saved during a sync. WHOOP says its step
algorithm runs on the band, and another open-source project (atria) reports a firmware step counter it has not
published. This is the read-only test that looks for it: walk a counted number of steps without the phone,
sync, and find a number in the synced data that rose by that much.

It sends nothing to the band. ZENO performs only the sync it does every day; the probe works offline on a copy
of the app's data. Commands 55, 58, 59, 60 and 64 (save or send raw motion), 0x69 (dense motion storage), 81
(timed raw capture) and any settings or firmware change are out of scope.

## 1. Before the walk

- Open ZENO and let it finish syncing, then force-quit it (swipe it away in the app switcher). The band keeps
  the walk until ZENO next syncs, and a sync clears the band's copy, so the first sync after the walk must save
  raw frames. If the WHOOP app is on the phone, keep it closed too.
- Leave the phone at home. Take a tally counter, or count each hundred on your fingers.

## 2. The walk

Note the clock time at each change; a wall clock is enough, because the band's own data shows the exact
boundaries.

| | What | How long |
|---|---|---|
| 1 | Sit still | 5 min |
| 2 | Move your arms with your feet still (stir, gesture, type) | 2 min |
| 3 | Walk 500 counted steps, normal pace | about 5 min |
| 4 | Stand still | 2 min |
| 5 | Walk 300 counted steps, slow | about 4 min |
| 6 | Sit still | 5 min |

A second session on another day with different counts (say 800 normal and 200 fast) shows whether a candidate
rises in proportion.

## 3. Back home: save the sync's raw frames

Plug the iPhone into the Mac and unlock it. ZENO has a switch that saves every raw frame of a sync, with no
button for it in the app; launching ZENO from the Mac with one argument turns it on for that run only:

```
xcrun devicectl device process launch --device <iPhone> --terminate-existing <ZENO bundle id> -enableRawCapture YES
```

Keep ZENO open on screen until the sync finishes, then copy its data folder to the Mac:

```
xcrun devicectl device copy from --device <iPhone> --domain-type appDataContainer \
  --domain-identifier <ZENO bundle id> \
  --source "Library/Application Support/OpenWhoop" --destination ~/zeno-walk-test
```

The next normal launch of ZENO has raw saving off again, and saved frames are cleared after 24 hours. The copied
folder is your full health history: keep it on the Mac and out of the repository.

## 4. The analysis

```
cd Tools/zeno/steps-probe
python3 steps_probe.py census ~/zeno-walk-test --tz America/New_York
python3 steps_probe.py scan ~/zeno-walk-test --tz America/New_York \
  --still 2026-10-09T10:00 2026-10-09T10:05 \
  --arms  2026-10-09T10:05 2026-10-09T10:07 \
  --walk  2026-10-09T10:07 2026-10-09T10:13 500 \
  --still 2026-10-09T10:13 2026-10-09T10:15 \
  --walk  2026-10-09T10:15 2026-10-09T10:20 300 \
  --still 2026-10-09T10:20 2026-10-09T10:25
python3 steps_probe.py text ~/zeno-walk-test
```

- `census`: the packet types the band sent, the history layouts (v24 or v25) and record sizes, and how many
  history records arrived per minute and per hour. One a second all day is dense storage.
- `scan`: every byte position of the history records, read as 1-, 2- and 4-byte numbers, scored as a counter.
  Bytes 92-93 of layout 24, where atria found a motion counter, are reported first.
  - **step counter?** Within 10% of your counts on both walks (or exactly half, if it counts one foot), flat at
    rest, little rise with arm movement, the same ratio on both walks.
  - **motion counter?** Rises 1.0-1.6 per step and also climbs with arm movement. Not a step count, but a better
    signal for the hour-by-hour merge than the motion sum ZENO uses now.
- `text`: readable text in the strap's other packets (its logs) that mentions steps.

`python3 -m unittest test_steps_probe` checks the probe on a synthetic sync with both kinds of counter planted.
