#!/bin/bash
# build.sh — Compile, assemble and sign the Mika+Grid app bundle.
#
# Since feature 01 the bundle comes from `xcodebuild`, not from `swift build` plus a
# hand-assembled bundle: archiving for App Store Connect needs an Xcode project, and one
# build path for both targets beats two that drift apart. `project.yml` is the source of
# truth; `MikaGrid.xcodeproj` is generated and git-ignored.
#
# What did NOT change: this script still produces build/Mika+Grid.app, still signs
# inside-out without --deep, and still falls back to an ad-hoc signature.
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
SCHEME="MikaGrid (Direct)"
# Separate derived data per target: both app targets produce Mika+Grid.app, and in a shared
# products directory the App Store bundle inherits Sparkle.framework from this one — exactly
# what AK-02 rules out.
DERIVED="$BUILD_DIR/xcode-direct"

CLEAN=false
UNIVERSAL=false
for arg in "$@"; do
    case "$arg" in
        --clean)     CLEAN=true ;;
        --universal) UNIVERSAL=true ;;
    esac
done

# Developer ID if available, ad-hoc otherwise. Auto-detect keeps the common case zero-config.
#
# The `|| true` is load-bearing: with `set -e` and `pipefail`, a grep that finds nothing
# exits 1 and takes the whole script with it. That is exactly the case on a machine without
# a signing certificate — a CI runner, or a fresh checkout.
detect_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/' || true
}
SIGN_IDENTITY="${SIGN_IDENTITY:-$(detect_identity)}"
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY="-"
    echo "==> No Developer ID found — signing ad-hoc (not distributable, see B09/FB-01)"
else
    echo "==> Signing as: $SIGN_IDENTITY"
fi

if [ "$CLEAN" = true ]; then
    echo "==> Cleaning build directories..."
    rm -rf "$PROJECT_DIR/.build" "$DERIVED"
fi

cd "$PROJECT_DIR"

command -v xcodegen >/dev/null || {
    echo "ERROR: xcodegen not found. Install it with 'brew install xcodegen'." >&2
    echo "       project.yml is the source of truth for both build targets." >&2
    exit 1
}

echo "==> Generating Xcode project from project.yml..."
xcodegen generate --quiet

echo "==> Building $SCHEME..."
XCODE_FLAGS=(
    -project "MikaGrid.xcodeproj"
    -scheme "$SCHEME"
    -configuration Release
    -derivedDataPath "$DERIVED"
    -destination 'platform=macOS'
    # This script signs the bundle itself, inside-out and without --deep. Letting Xcode
    # sign first would only be overwritten below.
    CODE_SIGNING_ALLOWED=NO
)
if [ "$UNIVERSAL" = true ]; then
    XCODE_FLAGS+=(ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO)
    echo "    (universal binary: arm64 + x86_64)"
fi

xcodebuild "${XCODE_FLAGS[@]}" build 2>&1 | tail -5

BUILT_APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
    echo "ERROR: xcodebuild produced no bundle at $BUILT_APP" >&2
    exit 1
fi

echo "==> Staging bundle to $APP_BUNDLE..."
mkdir -p "$BUILD_DIR"
rm -rf "$APP_BUNDLE"
cp -R "$BUILT_APP" "$APP_BUNDLE"

# --- Sanity checks -----------------------------------------------------------------------
# A missing framework used to be skipped silently, producing a bundle that cannot update and
# crashes on launch. It is a hard error now.
SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
if [ ! -d "$SPARKLE_DIR" ]; then
    echo "ERROR: Sparkle.framework missing from the built bundle." >&2
    echo "       Shipping without it would produce a bundle that cannot auto-update" >&2
    echo "       and crashes at launch." >&2
    exit 1
fi
CORE_FW="$APP_BUNDLE/Contents/Frameworks/MikaGridCore.framework"
if [ ! -d "$CORE_FW" ]; then
    echo "ERROR: MikaGridCore.framework missing from the built bundle." >&2
    exit 1
fi
if [ ! -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null \
        || echo "WARNING: Resources/AppIcon.icns missing — bundle gets the generic icon" >&2
fi

# --- Signing -----------------------------------------------------------------------------
# Inside-out, and WITHOUT --deep on the outer call.
#
# `codesign --deep` re-signs every nested component with the outer call's entitlements. That
# undid all of the careful per-component signing below and imprinted the app's entitlements
# — including disable-library-validation — onto Sparkle's XPC services, which ship with none.
# Apple documents --deep as a verification aid, not a signing mode.
[ "$SIGN_IDENTITY" = "-" ] && TS_SUFFIX="=none" || TS_SUFFIX=""
sign_component() {
    codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp"${TS_SUFFIX}" "$1"
}

echo "==> Signing nested Sparkle components (inside-out)..."
for xpc in "$SPARKLE_DIR"/Versions/B/XPCServices/*.xpc; do
    [ -d "$xpc" ] && sign_component "$xpc"
done
for app in "$SPARKLE_DIR"/Versions/B/*.app; do
    [ -d "$app" ] && sign_component "$app"
done
[ -f "$SPARKLE_DIR/Versions/B/Autoupdate" ] && sign_component "$SPARKLE_DIR/Versions/B/Autoupdate"
sign_component "$SPARKLE_DIR/Versions/B/Sparkle"
sign_component "$SPARKLE_DIR"

echo "==> Signing MikaGridCore.framework..."
sign_component "$CORE_FW/Versions/A"
sign_component "$CORE_FW"

# Ad-hoc builds still need library validation disabled: without a shared team identifier the
# app cannot load the embedded frameworks. Developer ID builds do not — keeping the
# entitlement there would weaken the hardened runtime for no reason.
# The source file is never modified: PlistBuddy rewrites a plist wholesale and drops its
# comments, so editing it in place would silently delete the explanation of why
# disable-library-validation is absent — on every single ad-hoc build.
ENTITLEMENTS="$PROJECT_DIR/Resources/MikaGrid.entitlements"
if [ "$SIGN_IDENTITY" = "-" ]; then
    ENTITLEMENTS="$BUILD_DIR/adhoc.entitlements"
    cp "$PROJECT_DIR/Resources/MikaGrid.entitlements" "$ENTITLEMENTS"
    /usr/libexec/PlistBuddy \
        -c "Add :com.apple.security.cs.disable-library-validation bool true" \
        "$ENTITLEMENTS" >/dev/null
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
