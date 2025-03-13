#!/bin/bash

# Central version information for QR Screen Scanner
# Include this file in other scripts to get consistent versioning

# Version information
export VERSION="1.0.4"
export BUILD_NUMBER="1"
export COPYRIGHT="Copyright © 2023 Andrew Khoury. All rights reserved."

# Function to update Info.plist files with the correct version
update_plist_versions() {
    local plist_file=$1
    
    if [ -f "$plist_file" ]; then
        # Use PlistBuddy if available, otherwise use sed
        if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$plist_file"
            /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$plist_file"
        else
            # Fallback to sed (less reliable)
            sed -i "" "s/<string>.*<\/string>/<string>$VERSION<\/string>/" "$plist_file"
            echo "Warning: PlistBuddy not found, using sed instead. Results may not be accurate."
        fi
        echo "Updated version in $plist_file to $VERSION (Build $BUILD_NUMBER)"
    else
        echo "Warning: $plist_file not found"
    fi
}

# Print version info when script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "QR Screen Scanner"
    echo "Version: $VERSION"
    echo "Build: $BUILD_NUMBER"
    echo "$COPYRIGHT"
fi 