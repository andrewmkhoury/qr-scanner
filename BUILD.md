# Building QR Screen Scanner

This document explains how to build the QR Screen Scanner app from source.

## Prerequisites

- macOS 11.0 or later
- Xcode 12.0 or later with Command Line Tools installed

## Build Process

The build process has been split into two steps to avoid issues with symlinks and to make it more reliable:

1. Build the executable using Swift Package Manager
2. Package the executable into a macOS app bundle and create a DMG

### Step 1: Build the Executable

Run the `simple_build.sh` script to build the executable:

```bash
./simple_build.sh
```

This script:
- Cleans the build directory
- Builds the project using Swift Package Manager
- Creates the executable at `.build/release/QRScreenScanner`

### Step 2: Create the App Bundle and DMG

Run the `package_dmg.sh` script to create the app bundle and DMG:

```bash
./package_dmg.sh
```

This script:
- Creates the app bundle structure
- Copies the executable and resources
- Creates the Info.plist and PkgInfo files
- Creates a DMG file with the app bundle

The resulting DMG file will be named `QRScreenScanner_v1.0.0.dmg`.

## All-in-One Build

If you prefer to run the entire build process in one step, you can use the `build.sh` script:

```bash
./build.sh
```

However, this script may take longer to run and could potentially hang if there are symlinks to system directories.

## Troubleshooting

### Build Hangs

If the build process hangs, it may be due to symlinks in the project directory. Check for and remove any symlinks to system directories:

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
2. Run `./simple_build.sh` to rebuild the executable
3. Run `./package_dmg.sh` to create a new app bundle and DMG 