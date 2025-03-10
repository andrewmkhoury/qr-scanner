#!/bin/bash

# Simple script to build QR Screen Scanner app
echo "=== Simple QR Screen Scanner Build Tool ==="
echo ""

# Clean build directory
echo "Cleaning build directory..."
rm -rf .build

# Build the project using Swift Package Manager with verbose output
echo "Building project using Swift Package Manager..."
swift build -c release -v

echo ""
echo "=== Build Complete ==="
echo "Check the output above for any errors."
echo "" 