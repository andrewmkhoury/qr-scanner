#!/bin/bash

# Script to generate exclude list for Package.swift
# This script uses find to list files matching specific patterns

OUTPUT_FILE="exclude_list.txt"

# Clear the output file
> "$OUTPUT_FILE"

echo "Generating exclude list for Package.swift..."

# Documentation files
echo "// Documentation files" >> "$OUTPUT_FILE"
echo "\"README.md\"," >> "$OUTPUT_FILE"
echo "\"PACKAGING.md\"," >> "$OUTPUT_FILE"
echo "\"LICENSE\"," >> "$OUTPUT_FILE"
echo "\"BUILD.md\"," >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Configuration files
echo "// Configuration files" >> "$OUTPUT_FILE"
echo "\"Info.plist\"," >> "$OUTPUT_FILE"
echo "\"QRScreenScanner-Info.plist\"," >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Asset files
echo "// Asset files" >> "$OUTPUT_FILE"
echo "\"AppIcon.iconset\"," >> "$OUTPUT_FILE"
echo "\"QRScanner-screenshot.png\"," >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Project files
echo "// Project files" >> "$OUTPUT_FILE"
echo "\"QRScreenScanner.xcodeproj\"," >> "$OUTPUT_FILE"
echo "\"docs\"," >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Shell scripts - dynamically generated
echo "// Shell scripts" >> "$OUTPUT_FILE"
find . -name "*.sh" -type f -maxdepth 1 | sed 's|^\./|"|' | sed 's|$|",|' | sort >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# DMG files - dynamically generated
echo "// DMG files" >> "$OUTPUT_FILE"
find . -name "QRScreenScanner*.dmg" -type f -maxdepth 1 | sed 's|^\./|"|' | sed 's|$|",|' | sort >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Directories
echo "// Directories" >> "$OUTPUT_FILE"
echo "\"Config\"," >> "$OUTPUT_FILE"
echo "\"test_view\"," >> "$OUTPUT_FILE"
echo "\"QR Scanner.app\"," >> "$OUTPUT_FILE"

echo "Exclude list generated in $OUTPUT_FILE"
echo "Copy the contents of this file to the exclude array in Package.swift" 