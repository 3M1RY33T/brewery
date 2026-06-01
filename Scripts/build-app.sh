#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
PRODUCT_NAME="Brewery"
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
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Built $APP_DIR"
