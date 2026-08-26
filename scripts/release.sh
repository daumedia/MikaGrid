#!/bin/bash
# release.sh — Build, sign, notarise, package and publish a Mika+Grid release.
#
# Replaces three steps that used to be manual and unchecked:
#   1. the appcast signature had to be copied by hand (a typo silently broke every update)
#   2. nothing verified that Info.plist, CHANGELOG, appcast and web/lib/app.ts agree
#   3. the feed lives on `master` while development happens on `main`
#
# Usage:
#   bash scripts/release.sh --check          verify only, change nothing
#   bash scripts/release.sh                  full release (direct / DMG / Sparkle)
#   bash scripts/release.sh --store          archive and upload the App Store build
#
# The two distribution routes are deliberately separate commands. They share the source
# tree and nothing else: different bundle id, different minimum system, different update
# mechanism. Running one must never touch the other (AK-22).
#
# Environment:
#   SIGN_IDENTITY      Developer ID Application identity (auto-detected)
#   NOTARY_PROFILE     keychain profile for notarytool; skip notarisation if unset
#   ASC_KEY_ID         App Store Connect API key id            (--store only)
#   ASC_ISSUER_ID      App Store Connect issuer id             (--store only)
#   ASC_KEY_PATH       path to the .p8 private key             (--store only)
#
# No credential is ever read from the repository (AK-28). The .p8 key belongs outside the
# working tree — ~/.appstoreconnect/private_keys/ is where Xcode looks for it.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Mika+Grid"
APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"
INSTALLER_DIR="$PROJECT_DIR/installer"
APPCAST="$PROJECT_DIR/appcast.xml"
FEED_BRANCH="${FEED_BRANCH:-master}"

CHECK_ONLY=false
STORE=false
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=true ;;
        --store) STORE=true ;;
    esac
done

fail() { echo "ERROR: $*" >&2; exit 1; }
ok()   { echo "  ✓ $*"; }

# --- 1 · consistency ----------------------------------------------------------------------
echo "==> Checking version consistency..."

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Resources/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/Resources/Info.plist")
ok "Info.plist: $VERSION (build $BUILD_NUMBER)"

grep -q "## \[$VERSION\]" "$PROJECT_DIR/CHANGELOG.md" \
    || fail "CHANGELOG.md has no '## [$VERSION]' entry"
ok "CHANGELOG.md has an entry for $VERSION"

WEB_VERSION=$(grep -E '^\s*version:' "$PROJECT_DIR/web/lib/app.ts" | sed -E 's/.*"(.*)".*/\1/')
[ "$WEB_VERSION" = "$VERSION" ] \
    || fail "web/lib/app.ts says $WEB_VERSION, Info.plist says $VERSION"
ok "web/lib/app.ts agrees"

WEB_DMG=$(grep -A1 'dmgUrl:' "$PROJECT_DIR/web/lib/app.ts" | grep -o 'v[0-9.]*/[^"]*' | head -1)
case "$WEB_DMG" in
    "v$VERSION"/*) ok "web/lib/app.ts download URL points at v$VERSION" ;;
    *) fail "web/lib/app.ts download URL points at $WEB_DMG, expected v$VERSION" ;;
esac

# Sparkle compares sparkle:version against CFBundleVersion. Entries that carry the marketing
# version there compare by luck, not by rule.
if grep -q "<sparkle:shortVersionString>$VERSION<" "$APPCAST"; then
    FEED_BUILD=$(grep -B2 "<sparkle:shortVersionString>$VERSION<" "$APPCAST" \
        | grep -o '<sparkle:version>[^<]*' | sed 's/.*>//')
    [ "$FEED_BUILD" = "$BUILD_NUMBER" ] \
        || fail "appcast sparkle:version is '$FEED_BUILD', Info.plist CFBundleVersion is '$BUILD_NUMBER'"
    ok "appcast.xml already carries $VERSION with matching build number"
    APPCAST_HAS_VERSION=true
else
    echo "  · appcast.xml has no entry for $VERSION yet — will be added"
    APPCAST_HAS_VERSION=false
fi

if [ "$CHECK_ONLY" = true ]; then
    echo ""
    echo "==> Check passed for v$VERSION"
    exit 0
fi

# --- 1b · App Store route -----------------------------------------------------------------
# Separate from everything below: the store build is sandboxed, carries no Sparkle and has
# its own bundle id. It never touches build/Mika+Grid.app or the appcast.
if [ "$STORE" = true ]; then
    MAS_PLIST="$PROJECT_DIR/Resources/Info-MAS.plist"
    MAS_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$MAS_PLIST")
    MAS_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$MAS_PLIST")
    [ "$MAS_VERSION" = "$VERSION" ] \
        || fail "Info-MAS.plist says $MAS_VERSION, Info.plist says $VERSION — keep both in step"
    ok "Info-MAS.plist agrees: $MAS_VERSION (build $MAS_BUILD)"

    # The store needs a different certificate than direct distribution. Saying so up front
    # beats a signing failure twenty minutes into an archive.
    security find-identity -v -p codesigning 2>/dev/null \
        | grep -q "3rd Party Mac Developer Application\|Apple Distribution" \
        || fail "no '3rd Party Mac Developer Application' or 'Apple Distribution' identity found.
       A 'Developer ID Application' certificate does NOT work for the App Store.
       Create the certificate and the app id lu.daumedia.mikagrid in App Store Connect."
    ok "store signing identity present"

    command -v xcodegen >/dev/null || fail "xcodegen not found — 'brew install xcodegen'"
    echo ""
    echo "==> Generating Xcode project..."
    (cd "$PROJECT_DIR" && xcodegen generate --quiet)

    ARCHIVE="$PROJECT_DIR/build/MikaGrid-MAS.xcarchive"
    EXPORT_DIR="$PROJECT_DIR/build/mas-export"
    rm -rf "$ARCHIVE" "$EXPORT_DIR"

    echo "==> Archiving the App Store target..."
    xcodebuild archive \
        -project "$PROJECT_DIR/MikaGrid.xcodeproj" \
        -scheme "MikaGrid (App Store)" \
        -configuration Release \
        -derivedDataPath "$PROJECT_DIR/build/xcode-mas" \
        -archivePath "$ARCHIVE" \
        -destination 'generic/platform=macOS' \
        | tail -5
    [ -d "$ARCHIVE" ] || fail "archiving produced no .xcarchive"
    ok "archived"

    # Sparkle must not be in there. Checked rather than assumed — the two targets used to
    # share a products directory, and the store bundle silently inherited it (AK-02).
    if find "$ARCHIVE/Products" -name "Sparkle.framework" -print -quit | grep -q .; then
        fail "the archive contains Sparkle.framework — the store build must not ship it (AK-02)"
    fi
    ok "no Sparkle in the archive (AK-02)"

    EXPORT_OPTIONS="$PROJECT_DIR/build/ExportOptions-MAS.plist"
    cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>teamID</key><string>CWJM4J4HFN</string>
    <key>destination</key><string>upload</string>
    <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

    EXPORT_FLAGS=(
        -exportArchive
        -archivePath "$ARCHIVE"
        -exportPath "$EXPORT_DIR"
        -exportOptionsPlist "$EXPORT_OPTIONS"
    )
    # Credentials come from the keychain or from a key outside the tree — never from here.
    if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ]; then
        EXPORT_FLAGS+=(
            -authenticationKeyID "$ASC_KEY_ID"
            -authenticationKeyIssuerID "$ASC_ISSUER_ID"
            -authenticationKeyPath "$ASC_KEY_PATH"
        )
        echo "==> Exporting and uploading to App Store Connect..."
    else
        echo "  ! ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH not set."
        echo "    Exporting only — Xcode will ask for credentials, or upload by hand."
        echo "    Set up once in App Store Connect → Users and Access → Integrations."
    fi

    xcodebuild "${EXPORT_FLAGS[@]}" | tail -5
    ok "exported to $EXPORT_DIR"

    echo ""
    echo "==> App Store build v$VERSION (build $MAS_BUILD) prepared"
    echo "    Archive: $ARCHIVE"
    echo ""
    echo "    Remaining manual steps:"
    echo "      1. App Store Connect → check the build appeared under TestFlight"
    echo "      2. Store listing must name the companion shortcut BEFORE download (AK-20)"
    echo "      3. Privacy details: 'Data Not Collected' (AK-21)"
    exit 0
fi

# --- 2 · build ----------------------------------------------------------------------------
echo ""
echo "==> Building..."
SIGN_IDENTITY="${SIGN_IDENTITY:-}" bash "$PROJECT_DIR/scripts/build.sh" --clean --universal

codesign -dvv "$APP_BUNDLE" 2>&1 | grep -q "Authority=Developer ID Application" \
    || fail "app is not signed with a Developer ID — Gatekeeper would reject it on other Macs"
ok "signed with Developer ID"

# --- 3 · DMG ------------------------------------------------------------------------------
echo ""
echo "==> Creating DMG..."
bash "$PROJECT_DIR/scripts/create-dmg-simple.sh"
DMG="$INSTALLER_DIR/$APP_NAME-v$VERSION.dmg"
[ -f "$DMG" ] || fail "DMG was not created at $DMG"

# The DMG itself was never signed before — the disk image carried no proof of origin at all.
# `|| true`: ohne Zertifikat liefert grep Exit 1 und beendet unter `set -e` das Skript.
IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/' || true)}"
if [ -n "$IDENTITY" ]; then
    echo "==> Signing DMG..."
    codesign --force --sign "$IDENTITY" --timestamp "$DMG"
    ok "DMG signed"
fi

# --- 4 · notarisation ---------------------------------------------------------------------
if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo ""
    echo "==> Notarising (this takes a few minutes)..."
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    spctl -a -vv -t install "$DMG" 2>&1 | head -3
    ok "notarised and stapled"
else
    echo ""
    echo "  ! NOTARY_PROFILE not set — skipping notarisation."
    echo "    Gatekeeper will show a warning on first launch on other Macs."
    echo "    Set it up once:  xcrun notarytool store-credentials MikaGrid \\"
    echo "                       --apple-id <id> --team-id CWJM4J4HFN --password <app-specific>"
fi

# --- 5 · appcast --------------------------------------------------------------------------
echo ""
echo "==> Signing update for the appcast..."
SIGN_UPDATE=$(find "$PROJECT_DIR/.build/artifacts" -name sign_update -perm +111 -print -quit)
[ -n "$SIGN_UPDATE" ] || fail "sign_update not found — run 'swift package resolve'"

SIGNATURE_LINE=$("$SIGN_UPDATE" "$DMG")
ok "signature generated"

if [ "$APPCAST_HAS_VERSION" = false ]; then
    echo ""
    echo "  Add this item to appcast.xml (newest first), then re-run:"
    echo ""
    echo "        <item>"
    echo "            <title>Version $VERSION</title>"
    echo "            <sparkle:version>$BUILD_NUMBER</sparkle:version>"
    echo "            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>"
    echo "            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>"
    echo "            <enclosure url=\"https://github.com/daumedia/MikaGrid/releases/download/v$VERSION/${APP_NAME//+/%2B}-v$VERSION.dmg\""
    echo "                       $SIGNATURE_LINE"
    echo "                       type=\"application/octet-stream\" />"
    echo "        </item>"
    echo ""
    exit 0
fi

# Verify the signature already in the feed matches the artefact we just built
# Nicht 'sed s/.*="//' benutzen: Der greedy Ausdruck verschluckt die Signatur an ihrem
# eigenen Base64-Ende ("…Cg==") und liefert eine leere Zeichenkette.
FEED_SIG=$(grep -A3 "download/v$VERSION" "$APPCAST" \
    | sed -nE 's/.*edSignature="([^"]+)".*/\1/p' | head -1)
if "$SIGN_UPDATE" --verify "$DMG" "$FEED_SIG" >/dev/null 2>&1; then
    ok "appcast signature matches the built DMG"
else
    fail "appcast signature does NOT match this DMG. Replace it with:
       $SIGNATURE_LINE"
fi

# --- 5b · optional: sign the feed itself ------------------------------------------------
# The enclosure signature proves each build is genuine, but not that a given entry is the
# NEWEST one — someone able to serve a replaced feed could offer an older, still validly
# signed version (a downgrade). Signing the feed closes that.
#
# Deliberately opt-in: once the feed is signed, every hand edit to appcast.xml must be
# re-signed or Sparkle rejects the feed outright and updates stop reaching users. For a
# project where releases are cut by hand, that failure mode is the larger risk. The transport
# is HTTPS to GitHub, which makes the attack impractical in the first place.
if [ "${SIGN_FEED:-false}" = "true" ]; then
    echo ""
    echo "==> Signing the appcast feed..."
    "$SIGN_UPDATE" "$APPCAST" --disable-signing-warning
    ok "feed signed — remember to re-sign after any manual edit"
fi

# --- 6 · feed branch ----------------------------------------------------------------------
# SUFeedURL points at $FEED_BRANCH. If that branch falls behind, no installed copy ever sees
# the new release — the app looks at exactly one address and nowhere else.
echo ""
echo "==> Syncing appcast to '$FEED_BRANCH'..."
CURRENT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "$FEED_BRANCH" ]; then
    ok "already on $FEED_BRANCH"
else
    echo "    git push origin $CURRENT_BRANCH:$FEED_BRANCH"
    echo "    (not run automatically — publish the GitHub release first)"
fi

echo ""
echo "==> Release v$VERSION prepared"
echo "    DMG: $DMG"
echo ""
echo "    Remaining manual steps:"
echo "      1. gh release create v$VERSION \"$DMG\" --title \"v$VERSION\" --notes-file <notes>"
echo "      2. git push origin $CURRENT_BRANCH:$FEED_BRANCH   # feed must not fall behind"
