#!/bin/bash
# Builds CopySave.app in this directory.
set -euo pipefail
cd "$(dirname "$0")"

APP="CopySave.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O src/main.swift -o "$APP/Contents/MacOS/CopySave" \
  -target arm64-apple-macosx13.0

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Copy Save</string>
  <key>CFBundleDisplayName</key><string>Copy Save</string>
  <key>CFBundleExecutable</key><string>CopySave</string>
  <key>CFBundleIdentifier</key><string>local.copysave</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Built $(pwd)/$APP"
