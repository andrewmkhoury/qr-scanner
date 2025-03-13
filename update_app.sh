#!/bin/bash

# Script to update the ResultView.swift file in the app bundle
# This is a simplified version that just copies the file

# Set variables
APP_NAME="QR Scanner"

# Print status message
echo "=== QR Screen Scanner Update Tool ==="
echo ""

# Check if the app exists
if [ ! -d "${APP_NAME}.app" ]; then
    echo "Error: App not found!"
    exit 1
fi

# Copy the updated ResultView.swift file
echo "Copying updated ResultView.swift file..."
mkdir -p "${APP_NAME}.app/Contents/Resources"
cp "ResultView.swift" "${APP_NAME}.app/Contents/Resources/"

echo ""
echo "=== Update Complete ==="
echo "The ResultView.swift file has been updated in the app bundle."
echo ""
echo "To test the app:"
echo "1. Run the app by double-clicking it"
echo ""
echo "Done!" 