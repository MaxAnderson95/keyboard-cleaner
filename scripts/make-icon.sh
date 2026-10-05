#!/bin/bash
# Renders assets/icon.svg into assets/KeyboardCleaner.icns and the README's assets/png/icon-256.png.
# QuickLook (WebKit) renders the SVG faithfully but onto white, so the tile shape is masked back out with magick.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -d "${TMPDIR:-/tmp}/kbc-icon.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

qlmanage -t -s 1024 -o "$tmp" assets/icon.svg >/dev/null
magick "$tmp/icon.svg.png" \
    \( -size 1024x1024 xc:none -fill white -draw "roundrectangle 101,101 922,922 184,184" \) \
    -compose CopyOpacity -composite "$tmp/icon-1024.png"

iconset="$tmp/KeyboardCleaner.iconset"
mkdir -p "$iconset"
for point in 16 32 128 256 512; do
    magick "$tmp/icon-1024.png" -resize "${point}x${point}" "$iconset/icon_${point}x${point}.png"
    magick "$tmp/icon-1024.png" -resize "$((point * 2))x$((point * 2))" "$iconset/icon_${point}x${point}@2x.png"
done
iconutil -c icns "$iconset" -o assets/KeyboardCleaner.icns
mkdir -p assets/png
cp "$iconset/icon_256x256.png" assets/png/icon-256.png
