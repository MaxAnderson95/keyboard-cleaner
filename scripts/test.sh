#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The Command Line Tools' macOS 27 SDK makes SwiftUI's @State a macro whose plugin CLT does not ship.
clt_sdk="$(xcode-select -p)/SDKs/MacOSX26.sdk"
[[ -d "$clt_sdk" ]] && export SDKROOT="${SDKROOT:-$clt_sdk}"
# Command Line Tools ships Testing as a framework outside SwiftPM's default search path, and only the
# native build system finds its macro plugin.
frameworks="$(xcode-select -p)/Library/Developer/Frameworks"
if [[ -d "$frameworks/Testing.framework" ]]; then
    swift test --build-system native --disable-xctest -Xswiftc -F -Xswiftc "$frameworks" -Xlinker -F -Xlinker "$frameworks" -Xlinker -rpath -Xlinker "$frameworks" -Xlinker -rpath -Xlinker "$(dirname "$frameworks")/usr/lib" "$@"
else
    swift test --disable-xctest "$@"
fi
