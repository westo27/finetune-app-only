#!/bin/bash
set -e

# AppMixer local build.
#
# Builds Release and installs AppMixer.app, signed ad-hoc so no Developer ID is
# needed. The re-sign at the end is not optional: hardened runtime turns on
# library validation, which requires embedded frameworks to share the main
# binary's Team ID. An ad-hoc signature has no Team ID, so the bundled
# Sparkle.framework fails the check and dyld aborts the process at launch. The
# local entitlements add com.apple.security.cs.disable-library-validation to
# permit it. A Developer ID build doesn't need this — both signatures carry the
# same Team ID — so scripts/build-dmg.sh is unaffected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/local"
APP="$BUILD_DIR/Build/Products/Release/AppMixer.app"

echo "==> Building Release (ad-hoc signed)..."
xcodebuild build \
    -project "$PROJECT_DIR/FineTune.xcodeproj" \
    -scheme FineTune \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGNING_REQUIRED=NO \
    DEVELOPMENT_TEAM= \
    | grep -E "^\*\* BUILD|error:" || true

test -d "$APP" || { echo "Build produced no app bundle"; exit 1; }

echo "==> Re-signing with library validation disabled..."
codesign --force --options runtime \
    --entitlements "$PROJECT_DIR/FineTune/FineTune-local.entitlements" \
    --sign - "$APP"
codesign -v --strict "$APP"

echo "==> Built: $APP"
echo
echo "To install:"
echo "  osascript -e 'quit app \"AppMixer\"' 2>/dev/null || true"
echo "  rm -rf /Applications/AppMixer.app && cp -R \"$APP\" /Applications/"
echo
echo "macOS will ask for Screen & System Audio Recording again: an ad-hoc"
echo "signature is a different identity as far as TCC is concerned."
