#!/bin/bash
# install.sh: set up automatic re-signing of ZENO on this Mac (see README.md).
#
# Usage:
#   Tools/zeno/resign/install.sh <iphone-id> [--installed-app <path.app>] [--repo <git-url>] [--branch <name>]
#   Tools/zeno/resign/install.sh --uninstall
#
#   <iphone-id>        the iPhone's identifier from `xcrun devicectl list devices` (the Identifier column)
#   --installed-app    the .app last installed on the iPhone, so the first run knows when its signature ends
#                      (without it, the first scheduled run re-signs straight away)
#   --repo             the repository to build (default: this checkout's `origin`)
#   --branch           the branch to build (default: main)
#
# Copies the script, xcodegen and Config/BundleIdSecrets.xcconfig into ~/Library/Application Support/ZENO-resign,
# clones the repository there (background jobs may not read ~/Downloads), and loads a LaunchAgent that runs
# zeno-resign.sh at 9:00, 13:00 and 21:00 (or when the Mac next wakes). Needs xcodegen on PATH or $XCODEGEN.

set -eu
LABEL="com.zeno.resign"
ROOT="$HOME/Library/Application Support/ZENO-resign"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
HERE=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$HERE/../../.." && pwd)

if [ "${1:-}" = "--uninstall" ]; then
    launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
    rm -f "$AGENT"
    rm -rf "$ROOT" "$HOME/Library/Caches/ZENO-resign"
    echo "Removed the LaunchAgent, $ROOT and its build cache."
    exit 0
fi
if [ $# -lt 1 ]; then
    sed -n '2,18p' "$0"
    exit 2
fi
DEVICE=$1
shift
INSTALLED_APP=""
REPO_URL=$(git -C "$REPO_DIR" remote get-url origin)
BRANCH=main
while [ $# -gt 0 ]; do
    case "$1" in
        --installed-app) INSTALLED_APP=$2; shift 2 ;;
        --repo) REPO_URL=$2; shift 2 ;;
        --branch) BRANCH=$2; shift 2 ;;
        *) echo "install.sh: unknown option $1" >&2; exit 2 ;;
    esac
done
XCODEGEN=${XCODEGEN:-$(command -v xcodegen || true)}
[ -x "$XCODEGEN" ] || { echo "install.sh: xcodegen not found (set XCODEGEN=/path/to/xcodegen)" >&2; exit 1; }
[ -f "$REPO_DIR/Config/BundleIdSecrets.xcconfig" ] || { echo "install.sh: Config/BundleIdSecrets.xcconfig is missing" >&2; exit 1; }
BUNDLE_PREFIX=$(sed -n 's/^BUNDLE_ID_PREFIX *= *//p' "$REPO_DIR/Config/BundleIdSecrets.xcconfig" | tr -d ' ')
BUNDLE_ID="$BUNDLE_PREFIX.noop"

mkdir -p "$ROOT/bin" "$ROOT/old-profiles" "$HOME/Library/Caches/ZENO-resign" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cp "$HERE/zeno-resign.sh" "$ROOT/zeno-resign.sh"
chmod +x "$ROOT/zeno-resign.sh"
# xcodegen with the resource bundle that sits beside it.
cp -R "$(dirname "$XCODEGEN")/." "$ROOT/bin/"
cp "$REPO_DIR/Config/BundleIdSecrets.xcconfig" "$ROOT/BundleIdSecrets.xcconfig"
if [ ! -d "$ROOT/src/.git" ]; then
    git clone -q --depth 1 --branch "$BRANCH" "$REPO_URL" "$ROOT/src"
fi
cat > "$ROOT/config" <<EOF
DEVICE="$DEVICE"
BUNDLE_ID="$BUNDLE_ID"
REPO_URL="$REPO_URL"
BRANCH="$BRANCH"
RENEW_DAYS=2
EOF

if [ -n "$INSTALLED_APP" ]; then
    iso=$(security cms -D -i "$INSTALLED_APP/embedded.mobileprovision" | plutil -extract ExpirationDate raw -o - -)
    echo "expires=$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%SZ' "$iso" +%s)" > "$ROOT/state"
fi

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$ROOT/zeno-resign.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Hour</key><integer>13</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Hour</key><integer>21</integer><key>Minute</key><integer>0</integer></dict>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/ZENO-resign.err.log</string>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"
echo "Installed. The LaunchAgent $LABEL runs at 9:00, 13:00 and 21:00 (or on wake)."
"$ROOT/zeno-resign.sh" --check
