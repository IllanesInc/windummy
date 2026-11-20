#!/bin/bash
# Builds "WinDummy.app" into ./build
#
#   ./scripts/build-app.sh            build
#   ./scripts/build-app.sh --run      build, then start the app
#
# Needs the Xcode Command Line Tools (xcode-select --install). Full Xcode is not required.
#
# Signing. macOS ties permissions (Screen Recording, Accessibility) to the app's
# signature. An ad hoc signature changes with every build, so the permissions
# have to be granted again after each rebuild. A fixed identity avoids that.
# The script uses the first of these that applies:
#
#   1. $CODESIGN_IDENTITY, if set
#   2. a certificate named "WinDummy Dev" in your keychain (see the README)
#   3. ad hoc signing

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="WinDummy"
EXECUTABLE="WinDummy"
APP_DIR="build/${APP_NAME}.app"
LOCAL_IDENTITY="WinDummy Dev"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    IDENTITY="${CODESIGN_IDENTITY}"
elif security find-certificate -c "${LOCAL_IDENTITY}" >/dev/null 2>&1; then
    IDENTITY="${LOCAL_IDENTITY}"
else
    IDENTITY="-"
fi

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

if [ "${IDENTITY}" = "-" ]; then
    echo "==> Signing ad hoc (macOS will ask for permissions again after this build)"
    codesign --force --sign - "${APP_DIR}"
else
    echo "==> Signing with \"${IDENTITY}\""
    if ! codesign --force --sign "${IDENTITY}" "${APP_DIR}"; then
        echo "    That failed, so the app is signed ad hoc instead."
        codesign --force --sign - "${APP_DIR}"
    fi
fi

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
