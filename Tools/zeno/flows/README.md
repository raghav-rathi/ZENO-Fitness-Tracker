# ZENO flow tests

End-to-end checks of ZENO's WHOOP-style interface with real (synthesized) taps, on the deterministic demo store.

- **NavigationFlowTests** walk the spec's navigation map (docs/zeno/WHOOP_UI_SPEC.md §1.8): every tab root, the Home
  header (Profile, Day Streak, Device Settings, the day pager), the Sleep / Recovery / Strain dials to their deep dives,
  the monitors, every My Day row, the ＋ menu, the Coach button, and the Health, Trends and More rows.
- **ConsistencyFlowTests** check that one fact reads the same on every screen that shows it (AGENTS.md "two readouts
  of one fact"): Recovery, Sleep and Strain on Home, the dives and Trends; HRV and resting heart rate on the Recovery
  dive, Trends and the Health Monitor; stress on Home, the Stress Monitor, Trends and the Health tab; tonight's
  bedtime and wake on Home and the Sleep Planner.

Run them against a simulator build of the app:

```
xcodebuild -project Strand.xcodeproj -scheme NOOPiOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -derivedDataPath build/DD CODE_SIGNING_ALLOWED=NO build
Tools/zeno/flows/run.sh <sim-udid> "build/DD/Build/Products/Debug-iphonesimulator/NOOP Staging.app"
```

The suite drives the installed app by its bundle id from a small host app (`XCUIApplication(bundleIdentifier:)`), so
it needs no test target inside the app's project. Each step saves a screenshot and an accessibility dump to `out/`.
