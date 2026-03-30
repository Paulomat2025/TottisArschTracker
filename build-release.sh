#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
echo "=== Building Tottis Arsch Tracker v$VERSION ==="

DIST="dist"
rm -rf "$DIST"
mkdir -p "$DIST"

# ── macOS ──────────────────────────────────────────
echo ""
echo "▸ Building macOS..."
cd mac
swift build -c release
cd ..

APP="$DIST/TottisArschTracker.app/Contents"
mkdir -p "$APP/MacOS" "$APP/Resources"

cp mac/.build/release/ArtTimeTracker "$APP/MacOS/TottisArschTracker"

# Resources (fart sound)
if [ -d "mac/.build/release/ArtTimeTracker_ArtTimeTracker.bundle" ]; then
    cp mac/.build/release/ArtTimeTracker_ArtTimeTracker.bundle/fart-sound.wav "$APP/Resources/"
else
    cp core/fart-sound.wav "$APP/Resources/"
fi

cat > "$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Tottis Arsch Tracker</string>
    <key>CFBundleIdentifier</key>
    <string>com.paulomat.tottisarschtracker</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>TottisArschTracker</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# DMG
echo "▸ Creating DMG..."
hdiutil create -volname "TottisArschTracker" \
    -srcfolder "$DIST/TottisArschTracker.app" \
    -ov -format UDZO \
    "$DIST/TottisArschTracker-macOS-v${VERSION}.dmg"

rm -rf "$DIST/TottisArschTracker.app"

echo ""
echo "✓ macOS: dist/TottisArschTracker-macOS-v${VERSION}.dmg"

# ── Windows (cross-compile) ────────────────────────
if command -v dotnet &> /dev/null; then
    echo ""
    echo "▸ Building Windows..."
    dotnet publish windows -c Release -r win-x64 --self-contained \
        -p:PublishSingleFile=true \
        -p:IncludeNativeLibrariesForSelfExtract=true \
        -p:Version="$VERSION" \
        -o "$DIST/win-tmp" 2>/dev/null

    mkdir -p "$DIST/TottisArschTracker-Windows"
    cp "$DIST/win-tmp/ArtTimeTracker.Windows.exe" "$DIST/TottisArschTracker-Windows/TottisArschTracker.exe"
    cp core/fart-sound.wav "$DIST/TottisArschTracker-Windows/fart-sound.wav"

    # ZIP
    cd "$DIST"
    zip -r "TottisArschTracker-Windows-v${VERSION}.zip" TottisArschTracker-Windows/
    cd ..

    rm -rf "$DIST/win-tmp" "$DIST/TottisArschTracker-Windows"

    echo "✓ Windows: dist/TottisArschTracker-Windows-v${VERSION}.zip"
else
    echo ""
    echo "⚠ dotnet nicht installiert — Windows-Build übersprungen"
fi

echo ""
echo "=== Done! Files in dist/ ==="
ls -lh "$DIST"/*.{dmg,zip} 2>/dev/null
