#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/../extension"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="Read Aloud"

echo "==> Converting Chrome extension to Safari..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcrun safari-web-extension-converter "$EXT_DIR" \
  --project-location "$BUILD_DIR" \
  --app-name "$APP_NAME" \
  --bundle-identifier "build.flaky.read-aloud" \
  --swift \
  --macos-only \
  --no-open \
  --no-prompt

echo "==> Building Safari extension..."
XCODE_PROJECT="$BUILD_DIR/$APP_NAME/$APP_NAME.xcodeproj"

xcodebuild -project "$XCODE_PROJECT" \
  -scheme "$APP_NAME (macOS)" \
  -configuration Release \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  DSTROOT="$BUILD_DIR/dst" \
  install

echo "==> Installing to ~/Applications..."
mkdir -p "$HOME/Applications"
APP_PATH="$BUILD_DIR/dst/Applications/$APP_NAME.app"

if [ -d "$APP_PATH" ]; then
  rm -rf "$HOME/Applications/$APP_NAME.app"
  cp -R "$APP_PATH" "$HOME/Applications/"
  echo "Installed: ~/Applications/$APP_NAME.app"
else
  # Fallback: find the .app in the build directory
  FOUND_APP=$(find "$BUILD_DIR" -name "*.app" -maxdepth 4 -type d | head -1)
  if [ -n "$FOUND_APP" ]; then
    rm -rf "$HOME/Applications/$APP_NAME.app"
    cp -R "$FOUND_APP" "$HOME/Applications/$APP_NAME.app"
    echo "Installed: ~/Applications/$APP_NAME.app"
  else
    echo "WARNING: Could not find built .app bundle"
    echo "Check $BUILD_DIR for the built project"
    exit 1
  fi
fi

echo "==> Done! Enable in Safari:"
echo "    Safari > Settings > Extensions > Read Aloud"
echo "    For unsigned: Develop > Allow Unsigned Extensions (resets per launch)"
