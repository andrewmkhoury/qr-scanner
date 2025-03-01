#!/bin/bash

# Create iconset directory if it doesn't exist
mkdir -p AppIcon.iconset

# Generate all required icon sizes
sips -z 16 16 appicon.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32 appicon.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32 appicon.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64 appicon.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128 appicon.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256 appicon.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256 appicon.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512 appicon.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512 appicon.png --out AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 appicon.png --out AppIcon.iconset/icon_512x512@2x.png

# Convert the iconset to icns
iconutil -c icns AppIcon.iconset

echo "AppIcon.icns created successfully!" 