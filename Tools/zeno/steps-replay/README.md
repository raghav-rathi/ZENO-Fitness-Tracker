# steps-replay

Replays ZENO's hour-by-hour step fill (`StepsHourMerge`) over a copy of the app's database, on the Mac, with no
phone, strap or app involved. It uses the app's own analytics code, so its numbers are the app's. It prints:

1. **How your strap stores motion.** Rows per recorded hour, the share of each day's seconds covered, the
   minutes it judged as walking, and the usual gap between rows. Dense storage is about 3,600 rows an hour.
2. **Calibration.** How many hours count as carried (the phone counted at least 300 steps, the strap was
   recording as usual and saw walking, you were awake and not in a cycling, strength, rowing or swimming
   workout), and the pace learned from them: your steps per walking minute.
3. **Day by day.** For each day the strap recorded: what the day shows without the fill, what the strap adds,
   and in which hours.
4. **A hide-the-phone test.** For each carried hour in turn, it hides the phone's count, learns the pace without
   that day, lets the strap fill the hour, and compares what the strap put back with what the phone had counted,
   as a share of the day. The plan's targets are a median miss within 10% of the day and no lean beyond 5%.

## Getting the database

With the iPhone plugged into the Mac and unlocked (or on the same Wi-Fi with wireless pairing working). This
only reads from the phone:

```
xcrun devicectl list devices      # the iPhone's Identifier
xcrun devicectl device copy from --device <iPhone> --domain-type appDataContainer \
  --domain-identifier <ZENO bundle id> \
  --source "Library/Application Support/OpenWhoop" --destination ~/zeno-steps-data
```

The bundle id is `BUNDLE_ID_PREFIX.noop` from `Config/BundleIdSecrets.xcconfig`. The folder holds your full
health history: keep it on the Mac and out of the repository.

## Running it

```
cd Tools/zeno/steps-replay
swift run -c release steps-replay ~/zeno-steps-data/whoop.sqlite --days 60 --tz America/New_York
```

`--days` is the window (default 60, the app's calibration window); `--tz` defaults to the Mac's zone. Run it
on a copy: SQLite folds the `-wal` file into the database when it opens it.
