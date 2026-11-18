#!/bin/bash
# Builds "WinDummy.app" into ./build
#
#   ./scripts/build-app.sh            build
#   ./scripts/build-app.sh --run      build, then start the app
#
# Needs the Xcode Command Line Tools (xcode-select --install). Full Xcode is not required.
#
# The app is signed ad hoc by default. macOS ties permissions (Screen Recording,
# Accessibility) to the signature, so it may ask again after a rebuild. To keep
# them, sign with a real identity:
#
#   CODESIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" ./scripts/build-app.sh

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="WinDummy"
EXECUTABLE="WinDummy"
APP_DIR="build/${APP_NAME}.app"
IDENTITY="${CODESIGN_IDENTITY:--}"

echo "==> Compiling (release)"
mkdir -p build
# The full compiler output is kept in build/build.log; handy when a build fails.
swift build -c release 2>&1 | tee build/build.log
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "==> Assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${BIN_DIR}/${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/${EXECUTABLE}"
cp "Support/Info.plist" "${APP_DIR}/Contents/Info.plist"
if [ -f "Support/AppIcon.icns" ]; then
    cp "Support/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo "==> Signing"
codesign --force --sign "${IDENTITY}" "${APP_DIR}"

echo "==> Done: ${APP_DIR}"

if [ "${1:-}" = "--run" ]; then
    # Quit a copy that is already running, then start the fresh build.
    pkill -f "Contents/MacOS/${EXECUTABLE}" 2>/dev/null || true
    sleep 0.5
    open "${APP_DIR}"
    echo "==> Running. Look for the ⌘ icon in the menu bar."
else
    echo "    Start it with: open \"${APP_DIR}\""
fi
