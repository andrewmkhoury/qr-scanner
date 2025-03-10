#!/bin/bash

# Script to package QR Screen Scanner app into a DMG
# This script assumes the app has already been built

# Set variables
APP_NAME="QR Scanner"
APP_VERSION="1.0.0"
APP_BUILD="1"
DMG_NAME="QRScreenScanner_v${APP_VERSION}"
TEMP_APP="${APP_NAME}.app"
TEMP_DIR="temp_dmg"
BUILD_DIR=".build/release"

# Print status message
echo "=== QR Screen Scanner Packaging Tool ==="
echo "Version: ${APP_VERSION} (Build ${APP_BUILD})"
echo ""

# Check if the executable exists
if [ ! -f "${BUILD_DIR}/QRScreenScanner" ]; then
    echo "Error: Executable not found at ${BUILD_DIR}/QRScreenScanner"
    echo "Please run './simple_build.sh' first to build the app."
    exit 1
fi

# Clean up any previous temporary files
echo "Cleaning up previous temporary files..."
rm -rf "${TEMP_APP}" "${TEMP_DIR}" "${DMG_NAME}.dmg"

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${TEMP_APP}/Contents/"{MacOS,Resources}

# Copy executable
echo "Copying executable..."
cp "${BUILD_DIR}/QRScreenScanner" "${TEMP_APP}/Contents/MacOS/"
chmod +x "${TEMP_APP}/Contents/MacOS/QRScreenScanner"

# Copy resources
echo "Copying resources..."
cp "AppIcon.icns" "${TEMP_APP}/Contents/Resources/"
cp "appicon.png" "${TEMP_APP}/Contents/Resources/"

# Copy Swift source files for reference
echo "Copying Swift source files..."
mkdir -p "${TEMP_APP}/Contents/Resources/Sources"
cp "ResultView.swift" "${TEMP_APP}/Contents/Resources/Sources/"
cp "QRScreenScanner.swift" "${TEMP_APP}/Contents/Resources/Sources/"
cp "QRHighlightView.swift" "${TEMP_APP}/Contents/Resources/Sources/"
cp "CaptureWindowController.swift" "${TEMP_APP}/Contents/Resources/Sources/"
cp "SmartModeController.swift" "${TEMP_APP}/Contents/Resources/Sources/"
cp "main.swift" "${TEMP_APP}/Contents/Resources/Sources/"

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
    <string>com.andrewmkhoury.qrscreenscanner</string>
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
    <string>Copyright © 2023 Andrew Khoury. All rights reserved.</string>
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