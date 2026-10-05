#!/bin/bash
# zeno-resign.sh: keep ZENO signed on an iPhone with a free Apple ID, automatically.
#
# A free Apple ID signs an app you install yourself for 7 days. Run this daily (install.sh adds a
# LaunchAgent that runs it three times a day). While the build on the iPhone has more than RENEW_DAYS left,
# it does nothing. Inside that window it builds the latest main with a fresh signature, installs it on the
# iPhone over Wi-Fi or USB (an in-place update, so the app keeps its data) and posts a notification. When
# the iPhone can't be reached it posts a reminder instead, at most once a day.
#
# Usage: zeno-resign.sh [--check | --force]
#   --check   say when the build on the iPhone expires and whether the iPhone can be reached; change nothing
#   --force   re-sign and install now, whatever the expiry
#
# Settings live in "$ZENO_RESIGN_HOME/config" (default ~/Library/Application Support/ZENO-resign), written
# by install.sh: DEVICE (the iPhone's devicectl identifier), BUNDLE_ID, REPO_URL, BRANCH, RENEW_DAYS.
# Everything it touches is outside ~/Downloads, which background jobs may not read.

set -u
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
ROOT="${ZENO_RESIGN_HOME:-$HOME/Library/Application Support/ZENO-resign}"
if [ ! -f "$ROOT/config" ]; then
    echo "zeno-resign: no config in $ROOT (run install.sh first)" >&2
    exit 2
fi
# shellcheck source=/dev/null
. "$ROOT/config"
SRC="$ROOT/src"
XCODEGEN="$ROOT/bin/xcodegen"
STATE="$ROOT/state"
OLD_PROFILES="$ROOT/old-profiles"
DERIVED="$HOME/Library/Caches/ZENO-resign/DD"
PROFILES="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
LOG="$HOME/Library/Logs/ZENO-resign.log"
LOCK="$ROOT/.lock"
MODE="${1:-auto}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }
notify() {
    osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true
}
human() { date -r "$1" '+%a %b %-d, %-I:%M %p'; }

# A provisioning profile's ExpirationDate, in epoch seconds.
profile_expiry() {
    local iso
    iso=$(security cms -D -i "$1" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null) || return 1
    TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%SZ' "$iso" +%s 2>/dev/null
}
profile_app_id() {
    security cms -D -i "$1" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null
}

state_get() { [ -f "$STATE" ] && sed -n "s/^$1=//p" "$STATE" | tail -1; }
state_set() {
    local tmp="$STATE.tmp"
    { [ -f "$STATE" ] && grep -v "^$1=" "$STATE"; echo "$1=$2"; } > "$tmp"
    mv "$tmp" "$STATE"
}

# The iPhone as devicectl sees it: connected, available (reachable on demand) or unavailable.
device_state() {
    local line
    line=$(xcrun devicectl list devices 2>/dev/null | grep -F "$DEVICE")
    case "$line" in
        *unavailable*) echo unavailable ;;
        *connected*) echo connected ;;
        *available*) echo available ;;
        *) echo unavailable ;;
    esac
}

now=$(date +%s)
expires=$(state_get expires)
expires=${expires:-0}
iphone=$(device_state)

if [ "$MODE" = "--check" ]; then
    if [ "$expires" -gt 0 ]; then
        echo "The build on the iPhone is signed until $(human "$expires") ($(( (expires - now) / 3600 )) h left)."
    else
        echo "No install recorded yet: the next run re-signs and installs."
    fi
    echo "Renews when fewer than $RENEW_DAYS days are left. The iPhone is $iphone."
    if [ -n "$(state_get installed_at)" ]; then
        echo "Last re-signed by this tool: $(human "$(state_get installed_at)") (commit $(state_get installed_commit))."
    else
        echo "Not re-signed by this tool yet."
    fi
    exit 0
fi

if [ "$MODE" != "--force" ] && [ "$now" -lt $(( expires - RENEW_DAYS * 86400 )) ]; then
    exit 0
fi

mkdir "$LOCK" 2>/dev/null || { log "another run is in progress"; exit 0; }
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
mkdir -p "$OLD_PROFILES" "$(dirname "$DERIVED")"

if [ "$iphone" = unavailable ]; then
    until_text=$( [ "$expires" -gt 0 ] && human "$expires" || echo "soon")
    log "due (signed until $until_text), but the iPhone can't be reached"
    if [ "$(state_get reminded)" != "$(date +%F)" ]; then
        notify "ZENO needs re-signing" "Unlock your iPhone on this Mac's Wi-Fi, or plug it in. ZENO stops opening $until_text."
        state_set reminded "$(date +%F)"
    fi
    exit 1
fi

fail() {
    log "FAILED: $1"
    notify "ZENO re-signing failed" "$1"
    exit 1
}

log "re-signing (the build on the iPhone is signed until $( [ "$expires" -gt 0 ] && human "$expires" || echo 'unknown'))"

# 1. The latest main, as pushed. A failed fetch (offline) builds the last checkout.
if git -C "$SRC" fetch -q --depth 1 origin "$BRANCH" 2>>"$LOG"; then
    git -C "$SRC" checkout -q --force --detach FETCH_HEAD
else
    log "could not fetch $BRANCH; building the last checkout"
fi
git -C "$SRC" reset -q --hard
cp "$ROOT/BundleIdSecrets.xcconfig" "$SRC/Config/BundleIdSecrets.xcconfig"
(cd "$SRC" && "$XCODEGEN" generate --quiet) >>"$LOG" 2>&1 || fail "the project could not be generated"

# 2. A fresh signature. Xcode keeps using a profile that is still valid, so the app's and its widget
#    extension's profiles that run out within RENEW_DAYS + 1 days are set aside; Xcode then asks Apple for
#    new 7-day ones. They are put back if the build fails.
moved=()
for f in "$PROFILES"/*.mobileprovision; do
    [ -f "$f" ] || continue
    case "$(profile_app_id "$f")" in
        *."$BUNDLE_ID" | *."$BUNDLE_ID".widgets) ;;
        *) continue ;;
    esac
    e=$(profile_expiry "$f") || continue
    if [ "$e" -lt $(( now + (RENEW_DAYS + 1) * 86400 )) ]; then
        mv "$f" "$OLD_PROFILES/" && moved+=("$OLD_PROFILES/$(basename "$f")")
    fi
done
restore_profiles() { for f in ${moved[@]+"${moved[@]}"}; do mv "$f" "$PROFILES/" 2>/dev/null; done; }

# 3. A signed Release build.
if ! xcodebuild -project "$SRC/Strand.xcodeproj" -scheme NOOPiOS -configuration Release \
        -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED" -allowProvisioningUpdates \
        build > "$ROOT/last-build.log" 2>&1; then
    restore_profiles
    reason=$(grep -m1 -E "error:" "$ROOT/last-build.log" | sed 's/^.*error: //' | cut -c1-120)
    fail "the build failed: ${reason:-see $ROOT/last-build.log}. If Apple asks you to sign in again, open Xcode › Settings › Accounts."
fi
APP=$(find "$DERIVED/Build/Products/Release-iphoneos" -maxdepth 1 -name '*.app' | head -1)
[ -n "$APP" ] || fail "the build made no app"
signed_until=$(profile_expiry "$APP/embedded.mobileprovision") || fail "the build has no signature"
if [ "$signed_until" -lt $(( now + 5 * 86400 )) ]; then
    restore_profiles
    fail "Apple did not issue a new signature (the build expires $(human "$signed_until"))."
fi

# 4. Install over the app already on the iPhone (same bundle id and team, so its data stays).
if ! xcrun devicectl device install app --device "$DEVICE" "$APP" > "$ROOT/last-install.log" 2>&1; then
    fail "the iPhone did not accept the install. Unlock it and keep it near this Mac; the next run tries again."
fi

commit=$(git -C "$SRC" rev-parse --short HEAD)
state_set expires "$signed_until"
state_set installed_at "$(date +%s)"
state_set installed_commit "$commit"
log "installed $commit, signed until $(human "$signed_until")"
notify "ZENO re-signed" "Updated on your iPhone. It now works until $(human "$signed_until")."
find "$OLD_PROFILES" -name '*.mobileprovision' -mtime +30 -delete 2>/dev/null
exit 0
