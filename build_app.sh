#!/bin/bash

# Script to build QR Screen Scanner app with the updated ResultView.swift
# This is a simplified version that doesn't rely on swift build

# Set variables
APP_NAME="QR Scanner"
APP_VERSION="1.0.0"
APP_BUILD="1"
APP_BUNDLE_ID="com.andrewmkhoury.qrscreenscanner"
APP_COPYRIGHT="Copyright © 2023 Andrew Khoury. All rights reserved."
DMG_NAME="QRScreenScanner_v${APP_VERSION}"
TEMP_APP="${APP_NAME}.app"
TEMP_DIR="temp_dmg"

# Print status message
echo "=== QR Screen Scanner Build Tool ==="
echo "Version: ${APP_VERSION} (Build ${APP_BUILD})"
echo ""

# Clean up any previous temporary files
echo "Cleaning up previous temporary files..."
rm -rf "${TEMP_APP}" "${TEMP_DIR}" "${DMG_NAME}.dmg"

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${TEMP_APP}/Contents/"{MacOS,Resources}

# Copy executable from existing app
echo "Copying executable from existing app..."
if [ -d "QR Scanner.app" ]; then
    cp "QR Scanner.app/Contents/MacOS/QR Scanner" "${TEMP_APP}/Contents/MacOS/QRScreenScanner"
    chmod +x "${TEMP_APP}/Contents/MacOS/QRScreenScanner"
else
    echo "Error: Existing app not found!"
    exit 1
fi

# Copy resources
echo "Copying resources..."
cp "AppIcon.icns" "${TEMP_APP}/Contents/Resources/"
cp "images/app-icon.png" "${TEMP_APP}/Contents/Resources/"
cp "ResultView.swift" "${TEMP_APP}/Contents/Resources/"

# Create Info.plist
echo "Creating Info.plist..."
cat > "${TEMP_APP}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>QRScreenScanner</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${APP_BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>${APP_COPYRIGHT}</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>This app needs access to screen recording to scan QR codes that appear on your screen.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "Creating PkgInfo..."
echo -n "APPL????" > "${TEMP_APP}/Contents/PkgInfo"

# Create temporary directory for DMG
echo "Setting up DMG structure..."
mkdir -p "${TEMP_DIR}"
cp -R "${TEMP_APP}" "${TEMP_DIR}/"

# Create symbolic link to /Applications
echo "Creating Applications folder symlink..."
ln -s /Applications "${TEMP_DIR}/Applications"

# Create DMG
echo "Creating DMG file..."
hdiutil create -volname "QR Screen Scanner" -srcfolder "${TEMP_DIR}" -ov -format UDZO "${DMG_NAME}.dmg"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

echo ""
echo "=== Packaging Complete ==="
echo "DMG file created: ${DMG_NAME}.dmg"
echo ""
echo "To test the app:"
echo "1. Mount the DMG by double-clicking it"
echo "2. Run the app from the mounted volume"
echo ""
echo "Done!" 