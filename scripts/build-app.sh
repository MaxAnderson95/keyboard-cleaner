#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The Command Line Tools' macOS 27 SDK makes SwiftUI's @State a macro whose plugin CLT does not ship.
clt_sdk="$(xcode-select -p)/SDKs/MacOSX26.sdk"
[[ -d "$clt_sdk" ]] && export SDKROOT="${SDKROOT:-$clt_sdk}"
swift build -c release --arch arm64
bin="$(swift build -c release --arch arm64 --show-bin-path)"

app="$PWD/build/Keyboard Cleaner.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/KeyboardCleaner" "$app/Contents/MacOS/KeyboardCleaner"
cp assets/KeyboardCleaner.icns "$app/Contents/Resources/KeyboardCleaner.icns"
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>net.maxanderson.keyboard-cleaner</string>
<key>CFBundleName</key><string>Keyboard Cleaner</string>
<key>CFBundleDisplayName</key><string>Keyboard Cleaner</string>
<key>CFBundleExecutable</key><string>KeyboardCleaner</string>
<key>CFBundleIconFile</key><string>KeyboardCleaner</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>$(date -u +%Y%m%d%H%M%S)</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
codesign --force --sign - "$app"
printf '%s\n' "$app"
