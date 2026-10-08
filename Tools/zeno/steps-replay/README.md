# steps-replay

Replays ZENO's hour-by-hour step merge (`StepsHourMerge`) over a copy of the app's database, on the Mac, with
no phone, band or app involved. It uses the app's own analytics code, so its numbers are the app's. It prints:

1. **How your band stores motion.** Rows per recorded hour, the share of each day's seconds covered, how often
   the reading changes, and the usual gap between rows. Dense storage is about 3,600 rows an hour while worn.
2. **Calibration.** How many hours count as carried (the phone counted at least 300 steps, the band was
   recording as usual, you were awake and not in a cycling, strength, rowing or swimming workout), the hourly
   factor learned from them, and the day-level factor ZENO used before, for comparison.
3. **Day by day.** What each day shows without the merge, what the band adds, and in which hours.
4. **A hide-the-phone test.** On days the phone was carried, it hides the phone's count for one to three hours
   that start with a walk, refits the factor without that day, lets the band fill, and compares what the band
   put back with what the phone had counted. The plan's targets are a median miss within 10% of the day and no
   lean beyond 5%.

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
