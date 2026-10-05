# Automatic re-signing for a free Apple ID

An app you install yourself with a free Apple ID is signed for 7 days; after that iOS won't open it until it
is signed again and reinstalled. `zeno-resign.sh` does that on a schedule from this Mac:

- Three times a day (9:00, 13:00, 21:00, or when the Mac next wakes) it checks how long the build on the
  iPhone has left. With more than 2 days left it does nothing.
- Inside those 2 days it fetches the latest `main` from GitHub, builds a Release with a fresh 7-day
  signature (`xcodebuild -allowProvisioningUpdates`, after setting the expiring profiles aside so Xcode asks
  Apple for new ones), and installs it over the app on the iPhone with `devicectl`. Same bundle id and
  team, so it is an in-place update and the app keeps its data.
- It posts a notification when it has updated the iPhone, when it could not reach the iPhone (at most once a
  day), or when something failed, such as Apple asking you to sign in to Xcode again.

## What it needs

- This Mac awake at some point inside the 2-day window, signed in to Xcode with the Apple ID that signs the
  app (Xcode › Settings › Accounts).
- The iPhone reachable: plugged in, or on the same Wi-Fi as the Mac with wireless pairing working (it shows
  as `available` or `connected` in `xcrun devicectl list devices` while unplugged). Keep it unlocked while an
  install runs.

## Set up, check, remove

```
XCODEGEN=/path/to/xcodegen Tools/zeno/resign/install.sh <iphone-id> --installed-app "<path to the .app installed last>"
"$HOME/Library/Application Support/ZENO-resign/zeno-resign.sh" --check    # expiry and whether the iPhone is reachable
"$HOME/Library/Application Support/ZENO-resign/zeno-resign.sh" --force    # re-sign and install now
Tools/zeno/resign/install.sh --uninstall
```

`<iphone-id>` is the Identifier column of `xcrun devicectl list devices`. Everything lives in
`~/Library/Application Support/ZENO-resign` (its own clone of the repository: background jobs may not read
`~/Downloads`), the build cache in `~/Library/Caches/ZENO-resign`, and the log in
`~/Library/Logs/ZENO-resign.log`. Re-run `install.sh` after changing the script.
