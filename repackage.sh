#!/bin/bash

# Script to repackage QR Screen Scanner app
# Created by Claude for Andrew Khoury

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
echo "=== QR Screen Scanner Repackaging Tool ==="
echo "Version: ${APP_VERSION} (Build ${APP_BUILD})"
echo ""

# Check if source files exist
if [ ! -f "QRScreenScanner.swift" ] || [ ! -f "AppIcon.icns" ]; then
    echo "Error: Source files not found!"
    exit 1
fi

# Clean up any previous temporary files
echo "Cleaning up previous temporary files..."
rm -rf "${TEMP_APP}" "${TEMP_DIR}" "${DMG_NAME}.dmg"

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${TEMP_APP}/Contents/"{MacOS,Resources}

# Copy executable (assuming it's already built)
echo "Copying executable..."
if [ -f ".build/release/QRScreenScanner" ]; then
    cp ".build/release/QRScreenScanner" "${TEMP_APP}/Contents/MacOS/"
    chmod +x "${TEMP_APP}/Contents/MacOS/QRScreenScanner"
else
    echo "Warning: Executable not found. You may need to build the project first."
    echo "Creating a placeholder executable..."
    touch "${TEMP_APP}/Contents/MacOS/QRScreenScanner"
    chmod +x "${TEMP_APP}/Contents/MacOS/QRScreenScanner"
fi

# Copy resources
echo "Copying resources..."
cp "AppIcon.icns" "${TEMP_APP}/Contents/Resources/"
cp "images/app-icon.png" "${TEMP_APP}/Contents/Resources/"

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
echo "To use this DMG in a GitHub release:"
echo "1. Go to your GitHub repository"
echo "2. Click on 'Releases'"
echo "3. Click 'Draft a new release'"
echo "4. Set the tag version to v${APP_VERSION}"
echo "5. Upload the ${DMG_NAME}.dmg file"
echo "6. Publish the release"
echo ""
echo "Done!" 