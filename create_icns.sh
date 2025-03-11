#!/bin/bash

# Create iconset directory
mkdir -p AppIcon.iconset

# Generate icons at different sizes
sips -z 16 16 images/app-icon.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32 images/app-icon.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32 images/app-icon.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64 images/app-icon.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128 images/app-icon.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256 images/app-icon.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256 images/app-icon.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512 images/app-icon.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512 images/app-icon.png --out AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 images/app-icon.png --out AppIcon.iconset/icon_512x512@2x.png

# Create icns file
iconutil -c icns AppIcon.iconset

# Clean up
rm -rf AppIcon.iconset

echo "AppIcon.icns created successfully" 