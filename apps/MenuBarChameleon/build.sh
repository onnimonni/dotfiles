#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MenuBarChameleon"
APP_BUNDLE="$HOME/Applications/${APP_NAME}.app"

# Use the Command Line Tools compiler with correct SDK
# (nix overrides SDKROOT with an old SDK, so we set it explicitly)
SWIFTC="/Library/Developer/CommandLineTools/usr/bin/swiftc"
SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"

echo "Building ${APP_NAME}..."

SDKROOT="$SDK" "$SWIFTC" -O -swift-version 5 \
    -o "/tmp/${APP_NAME}" \
    "${SCRIPT_DIR}/main.swift"

# Create .app bundle
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "/tmp/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "${SCRIPT_DIR}/Info.plist" "${APP_BUNDLE}/Contents/"

# Sign with developer identity so TCC permission persists across rebuilds
# (ad-hoc signing creates a new signature each time, breaking TCC)
IDENTITY=$(security find-identity -v -p codesigning | head -1 | sed 's/.*"\(.*\)"/\1/')
if [ -n "$IDENTITY" ]; then
    codesign -s "$IDENTITY" --force "${APP_BUNDLE}"
    echo "Signed with: $IDENTITY"
else
    codesign -s - --force "${APP_BUNDLE}"
    echo "Warning: No signing identity found, using ad-hoc (TCC will break on rebuild)"
fi

echo "Installed to ${APP_BUNDLE}"
echo ""
echo "To run:  open '${APP_BUNDLE}'"
echo "You will need to grant Screen Recording permission in:"
echo "  System Settings → Privacy & Security → Screen Recording"
