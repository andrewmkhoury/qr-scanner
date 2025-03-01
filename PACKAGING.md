# QR Screen Scanner Packaging Guide

This document explains how to package the QR Screen Scanner app for distribution.

## Available Scripts

There are three scripts available for packaging:

1. `repackage.sh` - Basic packaging script that creates a simple DMG
2. `repackage_pro.sh` - Advanced packaging script that creates a professional DMG with background and icon positioning
3. `create_simple_background.sh` - Helper script to create a background image for the DMG

## Basic Packaging

To create a basic DMG file:

```bash
./repackage.sh
```

This will:
- Create a new app bundle with the name "QR Scanner"
- Package it into a DMG file
- Include a shortcut to the Applications folder

## Professional Packaging

To create a professional DMG file with a custom background:

```bash
./repackage_pro.sh
```

This script requires either `wkhtmltoimage` or `ImageMagick` to create the background image. If neither is installed, it will create a DMG without a background.

To install the required tools:

```bash
# Install wkhtmltoimage
brew install wkhtmltopdf

# OR install ImageMagick
brew install imagemagick
```

## Creating a Background Image Manually

If you don't have `wkhtmltoimage` or `ImageMagick` installed, you can create a background image manually:

```bash
./create_simple_background.sh
```

This will create an HTML file that you can open in a browser. Take a screenshot of the page and save it as `dmg_background.png` in the project directory.

## Versioning

To change the version number:

1. Edit the `APP_VERSION` and `APP_BUILD` variables in the script you're using
2. Run the script to create a new DMG with the updated version

## Creating a GitHub Release

After creating the DMG file:

1. Go to your GitHub repository
2. Click on "Releases"
3. Click "Draft a new release"
4. Set the tag version to match your app version (e.g., "v1.0.0")
5. Upload the DMG file
6. Publish the release

## Troubleshooting

If users have issues opening the app:

1. They can right-click (or Control+click) on the app and select "Open"
2. If that doesn't work, they can run the following command in Terminal:
   ```
   xattr -cr /Applications/QR\ Scanner.app
   ```

## Long-term Solution

For a more robust solution, consider:

1. Getting an Apple Developer account to sign and notarize your app
2. Using a CI/CD pipeline to automate the build and signing process 