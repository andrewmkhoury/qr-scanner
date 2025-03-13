#!/bin/bash
# Script to prepare DMG files for GitHub to ensure they can be opened with right-click > Open

# Specify which DMG file to process
if [ $# -eq 0 ]; then
    # If no argument provided, find the latest DMG file
    DMG_FILE=$(ls -t QRScreenScanner_v*.dmg | head -1)
    if [ -z "$DMG_FILE" ]; then
        echo "Error: No DMG file found. Please specify a DMG file or build one first."
        exit 1
    fi
else
    DMG_FILE="$1"
    if [ ! -f "$DMG_FILE" ]; then
        echo "Error: File '$DMG_FILE' not found."
        exit 1
    fi
fi

echo "=== GitHub DMG Preparation Tool ==="
echo "Preparing DMG file: $DMG_FILE"

# Create a temporary directory
TEMP_DIR="temp_github_prep"
mkdir -p "$TEMP_DIR"

# Extract DMG to a temporary folder
echo "Mounting DMG..."
MOUNT_RESULT=$(hdiutil attach "$DMG_FILE" -nobrowse)
echo "Mount result: $MOUNT_RESULT"

# Find the mount point more reliably
MOUNT_POINT=$(echo "$MOUNT_RESULT" | grep "QR Screen Scanner" | awk '{print $3}')
if [ -z "$MOUNT_POINT" ]; then
    echo "Failed to determine mount point. Using fallback method..."
    MOUNT_POINT=$(echo "$MOUNT_RESULT" | tail -1 | awk '{print $3}')
fi

if [ -z "$MOUNT_POINT" ]; then
    echo "Error: Failed to mount DMG file properly."
    exit 1
fi

echo "Mounted at: $MOUNT_POINT"

echo "Copying contents to temp directory..."
cp -R "$MOUNT_POINT"/* "$TEMP_DIR/" || {
    echo "Error: Failed to copy contents from mounted DMG."
    hdiutil detach "$MOUNT_POINT" -force
    exit 1
}

echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -force

# Create a new DMG with a format that works better with GitHub
GITHUB_DMG="${DMG_FILE%.dmg}-github.dmg"
echo "Creating GitHub-optimized DMG: $GITHUB_DMG"

# Use a simpler DMG format that's more compatible with GitHub distribution
hdiutil create -volname "QR Screen Scanner" -srcfolder "$TEMP_DIR" -ov -format UDZO "$GITHUB_DMG"

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo ""
echo "=== Preparation Complete ==="
echo "Original DMG: $DMG_FILE"
echo "GitHub-ready DMG: $GITHUB_DMG"
echo ""
echo "Upload the GitHub-ready DMG to GitHub releases."
echo "Users should now be able to use right-click > Open after downloading."
echo ""

exit 0 