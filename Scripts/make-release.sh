#!/usr/bin/env bash
# Brewery release pipeline: bump the version, build and package the app, sign
# the update payload with the EdDSA private key, and regenerate a commit-ready
# appcast.xml. The developer then uploads the archive to a matching GitHub
# release and commits appcast.xml (plus the bumped VERSION and build-app.sh).
#
# Usage:
#   Scripts/make-release.sh <version> [build] [--notes-file <path>]
#
#   <version>  the new display version, e.g. "1.2.0".
#   [build]    the new CFBundleVersion integer; defaults to the previous build + 1.
#   --notes-file <path>  release notes for the appcast <description> (HTML or
#                        plain text); defaults to CHANGELOG.md if present.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:?usage: make-release.sh <version> [build] [--notes-file <path>]}"
shift

BUILD=""
NOTES_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --notes-file)
            NOTES_FILE="${2:?--notes-file needs a path}"
            shift 2
            ;;
        *)
            if [[ -z "$BUILD" ]]; then
                BUILD="$1"
                shift
            else
                echo "Unexpected argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

VERSION_FILE="$ROOT_DIR/VERSION"
if [[ -z "$BUILD" ]]; then
    if [[ -f "$VERSION_FILE" ]]; then
        PREV_BUILD="$(awk '{print $2}' "$VERSION_FILE")"
        BUILD=$((PREV_BUILD + 1))
    else
        echo "No VERSION file and no explicit build. Run with: make-release.sh <version> <build>" >&2
        exit 1
    fi
fi

if [[ -z "$NOTES_FILE" ]]; then
    NOTES_FILE="$ROOT_DIR/CHANGELOG.md"
fi

echo "Releasing Brewery $VERSION (build $BUILD)"

# Record the new version/build for the next release's auto-increment.
echo "$VERSION $BUILD" > "$VERSION_FILE"

# Build the app bundle with the new version, then package it. A release is
# built in release configuration so the DEBUG-only seams (--demo, --demo-update,
# --capture-visual) are compiled out of the shipped binary.
CONFIGURATION=release BREWERY_VERSION="$VERSION" BREWERY_BUILD="$BUILD" "$ROOT_DIR/Scripts/build-app.sh"

APP_DIR="$ROOT_DIR/.build/Brewery.app"
ARTIFACT_DIR="$ROOT_DIR/.build/release"
mkdir -p "$ARTIFACT_DIR"

# The zip is Sparkle's update payload (what the appcast enclosure points at);
# the DMG is for manual install from the GitHub release page.
ZIP="$ARTIFACT_DIR/Brewery-v$VERSION-macOS.zip"
DMG="$ARTIFACT_DIR/Brewery-v$VERSION-macOS.dmg"

ditto -c -k --keepParent "$APP_DIR" "$ZIP"
hdiutil create -volname "Brewery" -srcfolder "$APP_DIR" -ov -format UDZO "$DMG" >/dev/null

# Sign the update payload with the EdDSA private key. The signature is a raw
# Ed25519 signature over the archive bytes, base64-encoded — the same format
# Sparkle's own sign_update produces.
SIGNING_KEY="$ROOT_DIR/Keys/release-signing"
if [[ ! -f "$SIGNING_KEY" ]]; then
    echo "Missing signing key at Keys/release-signing. Run Scripts/generate-keys.sh first." >&2
    exit 1
fi

ED_SIGNATURE="$(openssl pkeyutl -sign -rawin -inkey "$SIGNING_KEY" -in "$ZIP" | base64)"
LENGTH="$(stat -f%z "$ZIP")"
ENCLOSURE_URL="https://github.com/3M1RY33T/brewery/releases/download/v$VERSION/Brewery-v$VERSION-macOS.zip"
PUB_DATE="$(date -R)"

# Release notes for the appcast <description>. Plain text is wrapped in CDATA;
# HTML is embedded as-is.
DESCRIPTION=""
if [[ -f "$NOTES_FILE" ]]; then
    DESCRIPTION="$(cat "$NOTES_FILE")"
else
    DESCRIPTION="Brewery $VERSION"
fi

# Regenerate the appcast with this release as the sole item. Multi-version
# history is intentionally out of scope this iteration; re-running this script
# replaces the appcast with the newest release.
cat > "$ROOT_DIR/appcast.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
    <title>Brewery</title>
    <link>https://github.com/3M1RY33T/brewery</link>
    <description>Brewery updates</description>
    <language>en</language>
    <item>
        <title>Version $VERSION</title>
        <pubDate>$PUB_DATE</pubDate>
        <sparkle:version>$BUILD</sparkle:version>
        <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
        <description><![CDATA[$DESCRIPTION]]></description>
        <enclosure
            url="$ENCLOSURE_URL"
            sparkle:edSignature="$ED_SIGNATURE"
            length="$LENGTH"
            type="application/octet-stream"/>
    </item>
</channel>
</rss>
XML

echo
echo "Built:"
echo "  $ZIP"
echo "  $DMG"
echo "Signed update payload (sparkle:edSignature):"
echo "  $ED_SIGNATURE"
echo "Regenerated: appcast.xml"
echo
echo "Next: upload $ZIP (and $DMG) to the GitHub release v$VERSION, then commit"
echo "appcast.xml, VERSION, and any build-app.sh version bump."
