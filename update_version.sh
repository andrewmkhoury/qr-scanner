#!/bin/bash

# Update version script for QR Screen Scanner
# This script updates the version in all necessary files

# Source the version information
source Config/version.sh

# Check for arguments
if [ "$#" -eq 1 ]; then
    # Update the version in the version.sh file
    sed -i "" "s/export VERSION=\"[0-9.]*\"/export VERSION=\"$1\"/" Config/version.sh
    echo "Updated version in Config/version.sh to $1"
    
    # Re-source to get the updated version
    source Config/version.sh
fi

# Update Info.plist files
update_plist_versions "Info.plist"
update_plist_versions "QRScreenScanner-Info.plist"

# Update build.sh
if [ -f "build.sh" ]; then
    sed -i "" "s/APP_VERSION=\"[0-9.]*\"/APP_VERSION=\"$VERSION\"/" build.sh
    echo "Updated version in build.sh to $VERSION"
else
    echo "Warning: build.sh not found"
fi

# Update Package.swift - Add the new DMG name to the exclude list
if [ -f "Package.swift" ]; then
    # Check if the version is already in the exclude list
    if ! grep -q "QRScreenScanner_v$VERSION.dmg" Package.swift; then
        # Add the new version DMG to the exclude list
        sed -i "" "/\"QRScreenScanner_v[0-9.]*.dmg\",/a\\
                \"QRScreenScanner_v$VERSION.dmg\"," Package.swift
        echo "Added QRScreenScanner_v$VERSION.dmg to Package.swift exclude list"
    else
        echo "QRScreenScanner_v$VERSION.dmg already exists in Package.swift"
    fi
else
    echo "Warning: Package.swift not found"
fi

echo ""
echo "Version update complete. New version: $VERSION (Build $BUILD_NUMBER)"
echo "Run ./build.sh to create a new DMG with the updated version." 