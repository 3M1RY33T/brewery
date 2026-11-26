#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
PRODUCT_NAME="Brewery"
# Display version and Sparkle build number. The release script overrides these;
# CFBundleVersion is the monotonic integer Sparkle compares on, so it bumps by
# one each release while the display version is free to be semver.
VERSION="${BREWERY_VERSION:-1.2.0}"
BUILD="${BREWERY_BUILD:-5}"
# Sparkle feed and EdDSA public key. The matching private key lives in the
# gitignored Keys/ directory and is never committed.
SU_FEED_URL="https://raw.githubusercontent.com/3M1RY33T/brewery/main/appcast.xml"
SU_PUBLIC_ED_KEY="LvldKYQNrli8XdLC33atFq4R2MfKkMrIjO1XhFuHljo="
ICON_NAME="BreweryIcon"
LOGO_PATH="$ROOT_DIR/Sources/Brewery/Resources/brewery-logo.png"
APP_DIR="$ROOT_DIR/.build/${PRODUCT_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$ROOT_DIR/.build/${ICON_NAME}.iconset"

cd "$ROOT_DIR"

swift build --product "$PRODUCT_NAME" --configuration "$CONFIGURATION"

TRIPLE_DIR="$(swift build --show-bin-path --configuration "$CONFIGURATION")"
BINARY_PATH="$TRIPLE_DIR/$PRODUCT_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_PATH" "$MACOS_DIR/$PRODUCT_NAME"

# Sparkle ships as a binary SwiftPM target; SwiftPM links the executable
# against @rpath/Sparkle.framework but does not embed the framework in an app
# bundle. Copy it into Contents/Frameworks and point the executable's rpath at
# it (the linker's own @loader_path only works in the .build tree).
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
SPARKLE_SRC="$TRIPLE_DIR/Sparkle.framework"
if [[ -d "$SPARKLE_SRC" ]]; then
    mkdir -p "$FRAMEWORKS_DIR"
    cp -R "$SPARKLE_SRC" "$FRAMEWORKS_DIR/Sparkle.framework"
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/$PRODUCT_NAME"
else
    echo "warning: Sparkle.framework not found at $SPARKLE_SRC; app will fail to link at runtime" >&2
fi

if [[ -f "$LOGO_PATH" ]]; then
    cp "$LOGO_PATH" "$RESOURCES_DIR/brewery-logo.png"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    sips -z 16 16 "$LOGO_PATH" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -z 32 32 "$LOGO_PATH" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$LOGO_PATH" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -z 64 64 "$LOGO_PATH" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$LOGO_PATH" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -z 256 256 "$LOGO_PATH" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$LOGO_PATH" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -z 512 512 "$LOGO_PATH" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$LOGO_PATH" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$LOGO_PATH" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/${ICON_NAME}.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>dev.brewery.Brewery</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>SUFeedURL</key>
    <string>$SU_FEED_URL</string>
    <key>SUPublicEDKey</key>
    <string>$SU_PUBLIC_ED_KEY</string>
    <key>SUAutomaticallyUpdate</key>
    <false/>
</dict>
</plist>
PLIST

# Ad-hoc sign the whole bundle so Info.plist and the icon are sealed; the
# linker only signs the executable, which codesign --verify rejects.
# The hardened runtime stops other programs injecting code into Brewery or
# attaching a debugger to it, either of which could read the administrator
# password it handles.
# The Sparkle framework is signed deeply first (it bundles Autoupdate,
# Updater.app and XPC services), so the app's own seal can cover it.
if [[ -d "$FRAMEWORKS_DIR/Sparkle.framework" ]]; then
    codesign --force --deep --options runtime --sign - "$FRAMEWORKS_DIR/Sparkle.framework"
fi
# The hardened runtime's library validation would otherwise reject the
# ad-hoc-signed Sparkle framework at launch; the entitlement disables that
# check (see Sources/Brewery/Brewery.entitlements).
ENTITLEMENTS_PATH="$ROOT_DIR/Sources/Brewery/Brewery.entitlements"
codesign --force --options runtime --entitlements "$ENTITLEMENTS_PATH" --sign - "$APP_DIR"

echo "Built $APP_DIR"
