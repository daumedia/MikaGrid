#!/bin/bash
# build.sh — Compile, assemble and sign the Mika+Grid app bundle.
#
# Signing identity:
#   Set SIGN_IDENTITY to a "Developer ID Application: …" identity to produce a bundle that
#   Gatekeeper accepts. Without it the script falls back to an ad-hoc signature, which is
#   fine locally but is rejected on every other Mac — see docs and B09/FB-01.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Mika+Grid"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

CLEAN=false
UNIVERSAL=false
for arg in "$@"; do
    case "$arg" in
        --clean)     CLEAN=true ;;
        --universal) UNIVERSAL=true ;;
    esac
done

# Developer ID if available, ad-hoc otherwise. Auto-detect keeps the common case zero-config.
SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')}"
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY="-"
    echo "==> No Developer ID found — signing ad-hoc (not distributable, see B09/FB-01)"
else
    echo "==> Signing as: $SIGN_IDENTITY"
fi

if [ "$CLEAN" = true ]; then
    echo "==> Cleaning .build/ directory..."
    rm -rf "$PROJECT_DIR/.build"
fi

echo "==> Building MikaGrid..."
cd "$PROJECT_DIR"

BUILD_FLAGS=(-c release)
if [ "$UNIVERSAL" = true ]; then
    BUILD_FLAGS+=(--arch arm64 --arch x86_64)
    echo "    (universal binary: arm64 + x86_64)"
fi

swift build "${BUILD_FLAGS[@]}" 2>&1
EXECUTABLE=$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)/MikaGrid

if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: build produced no executable at $EXECUTABLE" >&2
    exit 1
fi

echo "==> Assembling app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/MikaGrid"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "WARNING: Resources/AppIcon.icns missing — bundle gets the generic icon" >&2
fi

# --- Sparkle -----------------------------------------------------------------------------
# A missing framework used to be skipped silently, producing a bundle that cannot update and
# crashes on launch. It is a hard error now.
SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -path "*/macos-arm64_x86_64/Sparkle.framework" -print -quit 2>/dev/null || true)
if [ -z "$SPARKLE_FW" ]; then
    SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -name "Sparkle.framework" -print -quit 2>/dev/null || true)
fi
if [ -z "$SPARKLE_FW" ]; then
    echo "ERROR: Sparkle.framework not found under .build/artifacts." >&2
    echo "       Run 'swift package resolve' first. Shipping without it would produce" >&2
    echo "       a bundle that cannot auto-update and crashes at launch." >&2
    exit 1
fi

echo "==> Embedding Sparkle.framework..."
mkdir -p "$APP_BUNDLE/Contents/Frameworks"
cp -R "$SPARKLE_FW" "$APP_BUNDLE/Contents/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/MikaGrid"

# --- Signing -----------------------------------------------------------------------------
# Inside-out, and WITHOUT --deep on the outer call.
#
# `codesign --deep` re-signs every nested component with the outer call's entitlements. That
# undid all of the careful per-component signing below and imprinted the app's entitlements
# — including disable-library-validation — onto Sparkle's XPC services, which ship with none.
# Apple documents --deep as a verification aid, not a signing mode.
echo "==> Signing nested Sparkle components (inside-out)..."
SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
sign_component() {
    codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp"${TS_SUFFIX:-}" "$1"
}
[ "$SIGN_IDENTITY" = "-" ] && TS_SUFFIX="=none" || TS_SUFFIX=""

for xpc in "$SPARKLE_DIR"/Versions/B/XPCServices/*.xpc; do
    [ -d "$xpc" ] && sign_component "$xpc"
done
for app in "$SPARKLE_DIR"/Versions/B/*.app; do
    [ -d "$app" ] && sign_component "$app"
done
[ -f "$SPARKLE_DIR/Versions/B/Autoupdate" ] && sign_component "$SPARKLE_DIR/Versions/B/Autoupdate"
sign_component "$SPARKLE_DIR/Versions/B/Sparkle"
sign_component "$SPARKLE_DIR"

# Ad-hoc builds still need library validation disabled: without a shared team identifier the
# app cannot load the embedded Sparkle.framework. Developer ID builds do not — keeping the
# entitlement there would weaken the hardened runtime for no reason.
ENTITLEMENTS="$PROJECT_DIR/Resources/MikaGrid.entitlements"
if [ "$SIGN_IDENTITY" = "-" ]; then
    ENTITLEMENTS="$BUILD_DIR/adhoc.entitlements"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.disable-library-validation bool true" \
        -c "Save" "$PROJECT_DIR/Resources/MikaGrid.entitlements" 2>/dev/null || true
    cp "$PROJECT_DIR/Resources/MikaGrid.entitlements" "$ENTITLEMENTS"
    /usr/libexec/PlistBuddy -c "Delete :com.apple.security.cs.disable-library-validation" \
        "$PROJECT_DIR/Resources/MikaGrid.entitlements" 2>/dev/null || true
    echo "==> Ad-hoc build: adding disable-library-validation (required without a team identifier)"
fi

echo "==> Signing app bundle with hardened runtime..."
codesign --force --sign "$SIGN_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime --timestamp"${TS_SUFFIX}" \
    "$APP_BUNDLE"

echo "==> Verifying..."
codesign --verify --deep --strict --verbose=1 "$APP_BUNDLE"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")

echo ""
echo "==> Build complete: $APP_BUNDLE (v$VERSION)"
if [ "$SIGN_IDENTITY" = "-" ]; then
    echo ""
    echo "    NOTE: ad-hoc signed. Gatekeeper will reject this on other Macs."
    echo "    For distribution: SIGN_IDENTITY=\"Developer ID Application: …\" bash build.sh"
    echo "    then notarise the DMG — see scripts/release.sh"
fi
