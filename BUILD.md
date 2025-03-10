# Building QR Screen Scanner

This document explains how to build the QR Screen Scanner app from source.

## Prerequisites

- macOS 11.0 or later
- Xcode 12.0 or later with Command Line Tools installed

## Build Process

To build the QR Screen Scanner app, simply run the `build.sh` script:

```bash
./build.sh
```

This script performs the following steps:
1. Cleans up any previous temporary files
2. Checks for and removes problematic symlinks
3. Builds the project using Swift Package Manager
4. Creates the app bundle structure
5. Copies the executable and resources
6. Creates the Info.plist and PkgInfo files
7. Creates a DMG file with the app bundle

The resulting DMG file will be named `QRScreenScanner_v1.0.0.dmg`.

## Troubleshooting

### Build Hangs

If the build process hangs, it may be due to symlinks in the project directory. The script automatically checks for and removes the `dmg_contents` directory which often contains problematic symlinks. If you still experience issues, you can manually check for symlinks:

```bash
find . -type l -exec ls -la {} \;
```

### DMG Creation Issues

If you encounter issues creating the DMG, make sure there are no existing DMG files or app bundles in the project directory:

```bash
rm -rf "QR Scanner.app" QRScreenScanner_v*.dmg
```

### Swift Package Manager Issues

If Swift Package Manager reports errors about files not being handled, update the `Package.swift` file to exclude those files.

## Updating the App

To update the app:

1. Make your changes to the Swift source files
2. Run `./build.sh` to rebuild the app and create a new DMG 