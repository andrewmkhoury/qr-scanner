# QR Screen Scanner - Installation Instructions

Thank you for downloading QR Screen Scanner! Since this application is not signed with an Apple Developer ID certificate, macOS may show security warnings when you try to open it.

## Installation Options

### Option 1: Using the ZIP File (Recommended)

1. Download the `.zip` file from the GitHub release
2. Double-click to extract it
3. Right-click (or Control+click) on "QR Scanner.app" 
4. Select "Open" from the menu
5. Click "Open" when prompted about the unverified developer
6. The app should now open and you can drag it to your Applications folder

### Option 2: Using the DMG File

If you downloaded the DMG file:

1. Mount the DMG by double-clicking it
2. If you receive a "damaged" warning, open Terminal (Applications > Utilities > Terminal)
3. Copy and paste the following command:

```bash
xattr -d com.apple.quarantine "/Volumes/QR Screen Scanner/QR Scanner.app"
```

4. Press Enter to run the command
5. Now you can drag the app to your Applications folder and run it normally

### Option 3: After Installing to Applications Folder

If you've already copied the app to your Applications folder and it shows as "damaged":

1. Open Terminal (Applications > Utilities > Terminal)
2. Copy and paste the following command:

```bash
xattr -d com.apple.quarantine "/Applications/QR Scanner.app"
```

3. Press Enter to run the command
4. The app should now open normally

## Why This Happens

macOS includes security features that warn users about applications downloaded from the internet. These warnings are more severe for apps that aren't signed with an Apple Developer ID or notarized by Apple.

The commands above remove the "quarantine" attribute that macOS adds to downloaded files, which bypasses these security warnings.

## Is This Safe?

This app is open source and you can inspect the code on GitHub. The commands simply remove Apple's quarantine flag and don't modify the app itself. However, you should only run software from sources you trust. 