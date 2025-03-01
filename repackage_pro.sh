#!/bin/bash

# Advanced Script to repackage QR Screen Scanner app with a professional DMG
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
DMG_BACKGROUND="dmg_background.png"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"

# Print status message
echo "=== QR Screen Scanner Professional Repackaging Tool ==="
echo "Version: ${APP_VERSION} (Build ${APP_BUILD})"
echo ""

# Check if source files exist
if [ ! -f "QRScreenScanner.swift" ] || [ ! -f "AppIcon.icns" ]; then
    echo "Error: Source files not found!"
    exit 1
fi

# Clean up any previous temporary files
echo "Cleaning up previous temporary files..."
rm -rf "${TEMP_APP}" "${TEMP_DIR}" "${DMG_TEMP}" "${DMG_FINAL}"

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
cp "appicon.png" "${TEMP_APP}/Contents/Resources/"

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

# Create DMG background image if it doesn't exist
if [ ! -f "${DMG_BACKGROUND}" ]; then
    echo "Creating DMG background image..."
    cat > create_background.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #6e8efb, #a777e3);
            margin: 0;
            padding: 0;
            width: 600px;
            height: 400px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: white;
            text-align: center;
        }
        h1 {
            font-size: 32px;
            margin-bottom: 10px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        p {
            font-size: 16px;
            margin-top: 0;
            max-width: 80%;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
        }
        .instructions {
            margin-top: 40px;
            font-size: 14px;
            opacity: 0.9;
        }
        .arrow {
            font-size: 40px;
            margin: 20px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
    </style>
</head>
<body>
    <h1>QR Screen Scanner</h1>
    <p>Scan QR codes directly from your screen with ease</p>
    <div class="instructions">Drag the app to the Applications folder to install</div>
    <div class="arrow">→</div>
</body>
</html>
EOF

    # Convert HTML to image (requires wkhtmltoimage)
    if command -v wkhtmltoimage &> /dev/null; then
        wkhtmltoimage --width 600 --height 400 create_background.html "${DMG_BACKGROUND}"
        rm create_background.html
    else
        echo "Warning: wkhtmltoimage not found. Using a simple background instead."
        # Create a simple gradient background using convert (ImageMagick)
        if command -v convert &> /dev/null; then
            convert -size 600x400 gradient:"#6e8efb"-"#a777e3" "${DMG_BACKGROUND}"
        else
            echo "Warning: ImageMagick not found. No background will be used."
            touch "${DMG_BACKGROUND}"  # Create empty file
        fi
    fi
fi

# Create temporary directory for DMG
echo "Setting up DMG structure..."
mkdir -p "${TEMP_DIR}"
cp -R "${TEMP_APP}" "${TEMP_DIR}/"

# Create symbolic link to /Applications
echo "Creating Applications folder symlink..."
ln -s /Applications "${TEMP_DIR}/Applications"

# Create temporary DMG
echo "Creating temporary DMG..."
hdiutil create -volname "QR Screen Scanner" -srcfolder "${TEMP_DIR}" -ov -format UDRW "${DMG_TEMP}"

# Mount the temporary DMG
echo "Mounting temporary DMG..."
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP}" | grep Apple_HFS | awk '{print $3}')
echo "Mounted at: ${MOUNT_POINT}"

# Wait for the mount point to be ready
sleep 2

# Set DMG appearance
echo "Setting DMG appearance..."

# Copy background image if it exists and has content
if [ -s "${DMG_BACKGROUND}" ]; then
    mkdir -p "${MOUNT_POINT}/.background"
    cp "${DMG_BACKGROUND}" "${MOUNT_POINT}/.background/background.png"
fi

# Create .DS_Store with custom view settings
echo "Creating custom view settings..."
cat > applescript.scpt << EOF
tell application "Finder"
    tell disk "QR Screen Scanner"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "${APP_NAME}.app" of container window to {140, 200}
        set position of item "Applications" of container window to {460, 200}
        update without registering applications
        close
    end tell
end tell
EOF

# Run the AppleScript
osascript applescript.scpt || echo "Warning: AppleScript failed. DMG will have default appearance."
rm applescript.scpt

# Make sure Finder doesn't keep re-opening the DMG window
mdutil -i off "${MOUNT_POINT}"
sleep 1

# Make the DMG read-only and compressed
echo "Finalizing DMG..."
hdiutil detach "${MOUNT_POINT}"
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"
rm -f "${DMG_TEMP}"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}" "${TEMP_APP}"

echo ""
echo "=== Packaging Complete ==="
echo "DMG file created: ${DMG_FINAL}"
echo ""
echo "To use this DMG in a GitHub release:"
echo "1. Go to your GitHub repository"
echo "2. Click on 'Releases'"
echo "3. Click 'Draft a new release'"
echo "4. Set the tag version to v${APP_VERSION}"
echo "5. Upload the ${DMG_FINAL} file"
echo "6. Publish the release"
echo ""
echo "Done!" 