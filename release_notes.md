# QR Screen Scanner v1.0.4 Release Notes

## What's New
- Fixed coordinate transformation for QR code detection boxes
- Improved highlighting of detected QR codes
- Enhanced visual appearance of highlight boxes
- Various bug fixes and stability improvements

## Installation Instructions

Since this app is not signed with an Apple Developer ID certificate, macOS may display security warnings when downloaded.

### Recommended Installation Method:

1. Download the **ZIP file** (`QRScreenScanner_v1.0.4.zip`)
2. Extract the ZIP file
3. Right-click on "QR Scanner.app" and select "Open" 
4. Click "Open" when prompted about the unverified developer
5. You can now move the app to your Applications folder

### Alternative Method (Using DMG):

If you prefer the DMG installation:

1. Download the DMG file (`QRScreenScanner_v1.0.4.dmg`)
2. Mount the DMG by double-clicking it
3. If you see a "damaged" warning, open Terminal and run:
   ```
   xattr -d com.apple.quarantine "/Volumes/QR Screen Scanner/QR Scanner.app"
   ```
4. Once fixed, you can drag the app to your Applications folder

## Known Issues
- First-time launch requires right-click > Open due to macOS security
- App requires screen recording permission to function properly

## Support
If you encounter any issues, please report them on GitHub at https://github.com/andrewmkhoury/qr-code-scanner/issues 