#!/bin/bash
# run.sh: ZENO's end-to-end flow tests, with real taps, on an iOS Simulator.
#
# Usage:
#   Tools/zeno/flows/run.sh <sim-udid> <app-path> [out-dir]
#
# Installs <app-path> (a Debug-iphonesimulator ZENO build, e.g.
# build/DD/Build/Products/Debug-iphonesimulator/"NOOP Staging.app") fresh on the simulator, then runs the
# XCUITest suite in this folder against it. Every test launches the app on the deterministic demo store
# (--demo-seed). Screenshots and accessibility dumps of each step go to <out-dir> (default ./out).
#
# Needs xcodegen on PATH, or XCODEGEN=/path/to/xcodegen.

set -u
if [ $# -lt 2 ]; then
    sed -n '2,12p' "$0"
    exit 2
fi
UDID=$1
APP=$2
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${3:-$HERE/out}
XCODEGEN=${XCODEGEN:-xcodegen}

[ -d "$APP" ] || { echo "run.sh: no app at $APP" >&2; exit 1; }
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
mkdir -p "$OUT"

xcrun simctl boot "$UDID" >/dev/null 2>&1
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1
# Settings written by earlier runs survive an uninstall; start from none.
xcrun simctl spawn "$UDID" defaults delete "$BUNDLE_ID" >/dev/null 2>&1
xcrun simctl install "$UDID" "$APP" || exit 1

cd "$HERE" || exit 1
"$XCODEGEN" generate --quiet || exit 1
TEST_RUNNER_FLOW_OUT="$OUT" TEST_RUNNER_ZENO_BUNDLE_ID="$BUNDLE_ID" xcodebuild -project ZenoFlows.xcodeproj -scheme ZenoFlowTests \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$HERE/DD" test > "$OUT/test.log" 2>&1
status=$?
grep -E "Test Case.*(passed|failed)" "$OUT/test.log" | sed -E 's/.*ZenoFlowTests\.//'
grep -E "error: -\[" "$OUT/test.log" | sed -E 's/.*error: -\[ZenoFlowTests\.//'
exit $status
