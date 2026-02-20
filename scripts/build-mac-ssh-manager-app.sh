#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/mac-ssh-manager"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_DIR="$DIST_DIR/MacSSHManager.app"
APP_ICON_NAME="AppIcon.icns"

TERMINAL_ICON_PATH=""
for candidate in \
  "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" \
  "/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns"
do
  if [[ -f "$candidate" ]]; then
    TERMINAL_ICON_PATH="$candidate"
    break
  fi
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS only" >&2
  exit 1
fi

cd "$APP_DIR"
swift build -c release

mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Resources"
cp -f .build/release/MacSSHManager "$BUNDLE_DIR/Contents/MacOS/MacSSHManager"
if [[ -n "$TERMINAL_ICON_PATH" ]]; then
  cp -f "$TERMINAL_ICON_PATH" "$BUNDLE_DIR/Contents/Resources/$APP_ICON_NAME"
else
  echo "Warning: Terminal icon not found, default app icon will be used."
fi

cat > "$BUNDLE_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>MacSSHManager</string>
  <key>CFBundleIdentifier</key>
  <string>local.putty.macsshmanager</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MacSSHManager</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -n "$TERMINAL_ICON_PATH" ]]; then
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$BUNDLE_DIR/Contents/Info.plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $APP_ICON_NAME" "$BUNDLE_DIR/Contents/Info.plist"
fi

echo "Built app bundle: $BUNDLE_DIR"
