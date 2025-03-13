#!/bin/bash

# QR Screen Scanner Build Script
# This script builds the app from source and packages it as a macOS app

# Source version information
source Config/version.sh

# Set variables
APP_NAME="QR Scanner"
APP_VERSION="$VERSION"
APP_BUILD="$BUILD_NUMBER"
APP_BUNDLE_ID="com.andrewmkhoury.qrscreenscanner"
APP_COPYRIGHT="$COPYRIGHT"
DMG_NAME="QRScreenScanner_v${APP_VERSION}"
ZIP_NAME="QRScreenScanner_v${APP_VERSION}"
TEMP_APP="${APP_NAME}.app"
TEMP_DIR="temp_dmg"
BUILD_DIR=".build/release"

# Print status message
echo "=== QR Screen Scanner Build Tool ==="
echo "Version: ${APP_VERSION} (Build ${APP_BUILD})"
echo ""

# Clean up any previous temporary files
echo "Cleaning up previous temporary files..."
rm -rf "${TEMP_APP}" "${TEMP_DIR}" "${DMG_NAME}.dmg" "${ZIP_NAME}.zip"

# Check for and remove problematic symlinks
echo "Checking for problematic symlinks..."
if [ -d "dmg_contents" ]; then
    echo "Removing dmg_contents directory to prevent build issues..."
    rm -rf "dmg_contents"
fi

# Clean build directory
echo "Cleaning build directory..."
rm -rf .build

# Build the project using Swift Package Manager
echo "Building project using Swift Package Manager..."
swift build -c release

# Check if build was successful
if [ ! -f "${BUILD_DIR}/QRScreenScanner" ]; then
    echo "Error: Build failed! Executable not found at ${BUILD_DIR}/QRScreenScanner"
    exit 1
fi

echo "Build successful! Creating app bundle..."

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
cp "QRCodeGeneratorView.swift" "${TEMP_APP}/Contents/Resources/Sources/"
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

# Create a simpler DMG (more compatible)
echo "Creating DMG file using simpler format (better for GitHub)..."
hdiutil create -volname "QR Screen Scanner" -srcfolder "${TEMP_DIR}" -ov -format UDZO -imagekey zlib-level=9 "${DMG_NAME}-temp.dmg"

# Convert to read-only format
echo "Converting DMG to read-only format..."
hdiutil convert "${DMG_NAME}-temp.dmg" -format UDRO -o "${DMG_NAME}.dmg"
rm "${DMG_NAME}-temp.dmg"

# Create ZIP archive (more compatible for distribution without code signing)
echo "Creating ZIP archive..."
ditto -c -k --keepParent "${TEMP_APP}" "${ZIP_NAME}.zip"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}" "${TEMP_APP}"

echo ""
echo "=== Build Complete ==="
echo "DMG file created: ${DMG_NAME}.dmg"
echo "ZIP file created: ${ZIP_NAME}.zip"
echo ""
echo "DISTRIBUTION RECOMMENDATION:"
echo "For GitHub releases, include both the DMG and ZIP files."
echo "The DMG should now work with right-click > Open after downloading."
echo "If users still encounter issues, instruct them to use the ZIP file instead."
echo ""
echo "Done!" 