#!/bin/bash
# shoot.sh: capture Pulse screens from a DEBUG build in the iOS Simulator.
#
# Usage:
#   Tools/zeno/shoot.sh <sim-udid> <out-dir> <app-path> [--fresh] [--wait N] [target ...]
#
# Installs <app-path> (a Debug-iphonesimulator .app) on the simulator, launches it once per target with
# --demo-seed (the DEBUG harness that fills the store with deterministic data anchored on today), waits,
# and writes <out-dir>/<target>.png plus a downscaled <target>.jpg for viewing.
#
#   --fresh     uninstall first, so --demo-seed seeds a fresh store anchored on today
#   --wait N    seconds to wait after each launch before the screenshot (default 8; the first launch
#               after a fresh install waits twice as long while the seed runs)
#
# A target is one of:
#   home | health | trends | more    a tab root                     (--pulse-tab <tab>)
#   gallery                          the component gallery          (--pulse-gallery)
#   actions                          the ＋ menu                     (--pulse-sheet actions)
#   coach-sheet                      the Coach sheet / setup        (--pulse-sheet coach)
#   menu                             Home with the ＋ menu open      (--pulse-sheet menu)
#   <route>                          any route by name              (--pulse-route <route>), e.g.
#                                    sleep-dive, recovery-dive, strain-dive, sleep-planner, trend-view,
#                                    trend-view:rhr, healthspan, profile, journal, classic-settings, …
#                                    (the full list: PulseRoute.debugCatalog in Shell/PulseRoutes.swift)
# Quote a target to pass extra launch arguments after it; they are added verbatim and the file name is
# built from the whole string:
#   "home --pulse-scroll dashboard"  Home scrolled to My Dashboard
#   "home --pulse-day 3"             Home three days back
#   "home -noop.coachEnabled NO"     Home with Coach switched off (a UserDefaults launch argument)
#   "gallery --pulse-scroll gallery-charts"
#
# With no targets it shoots the four tab roots.
#
# Example:
#   Tools/zeno/shoot.sh 3F6D8EB8-27A5-4842-BAA1-AB85CCDF7242 /tmp/shots \
#     build/DD/Build/Products/Debug-iphonesimulator/"NOOP Staging.app" --fresh home "home --pulse-scroll dashboard" sleep-dive

set -u

usage() {
    # The header comment only (everything up to the first blank line after it).
    sed -n '2,36p' "$0"
}

if [ $# -lt 3 ]; then
    usage
    exit 2
fi

UDID=$1
OUT=$2
APP=$3
shift 3

FRESH=0
WAIT=8
TARGETS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --fresh) FRESH=1; shift ;;
        --wait)
            if [ $# -lt 2 ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "shoot.sh: --wait needs a number of seconds" >&2
                usage
                exit 2
            fi
            WAIT=$2; shift 2 ;;
        *) TARGETS+=("$1"); shift ;;
    esac
done
if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS=(home health trends more)
fi

if [ ! -d "$APP" ]; then
    echo "shoot.sh: no app at $APP (build the NOOPiOS scheme for the simulator first)" >&2
    exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
mkdir -p "$OUT"

# Boot the simulator if it is not running, and wait until it is usable.
xcrun simctl boot "$UDID" >/dev/null 2>&1
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
# A steady status bar, so captures compare cleanly.
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --wifiBars 3 --cellularMode active --cellularBars 4 >/dev/null 2>&1

if [ "$FRESH" = 1 ]; then
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1
fi
xcrun simctl install "$UDID" "$APP" || exit 1

first=1
for target in "${TARGETS[@]}"; do
    # Split the target into its name and any extra launch arguments.
    read -r -a words <<< "$target"
    name=${words[0]}
    extra=("${words[@]:1}")
    case "$name" in
        home|health|trends|more) args=(--pulse-tab "$name") ;;
        gallery) args=(--pulse-gallery) ;;
        actions) args=(--pulse-sheet actions) ;;
        menu) args=(--pulse-tab home --pulse-sheet menu) ;;
        coach-sheet) args=(--pulse-sheet coach) ;;
        *) args=(--pulse-route "$name") ;;
    esac
    file=$(printf '%s' "$target" | tr -c 'A-Za-z0-9._-' '_' | sed 's/__*/_/g; s/_$//')

    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1
    xcrun simctl launch "$UDID" "$BUNDLE_ID" --demo-seed "${args[@]}" ${extra[@]+"${extra[@]}"} >/dev/null || {
        echo "shoot.sh: launch failed for $target" >&2
        continue
    }
    if [ "$first" = 1 ] && [ "$FRESH" = 1 ]; then
        sleep $((WAIT * 2))
    else
        sleep "$WAIT"
    fi
    first=0

    xcrun simctl io "$UDID" screenshot "$OUT/$file.png" >/dev/null 2>&1
    sips -s format jpeg -s formatOptions 75 -Z 1100 "$OUT/$file.png" --out "$OUT/$file.jpg" >/dev/null 2>&1
    echo "$OUT/$file.png"
done

xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1
