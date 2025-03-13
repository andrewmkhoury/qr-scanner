#!/bin/bash

echo "=== QR Screen Scanner Rebuilding Tool (Test Fix) ==="

# Create a temporary directory
mkdir -p test_build
mkdir -p test_build/app

# Copy the existing app
echo "Copying existing app structure..."
cp -R "QR Scanner.app" test_build/app/

# Modify the Info.plist to change the bundle identifier (to avoid conflicts)
defaults write "$(pwd)/test_build/app/QR Scanner.app/Contents/Info" CFBundleIdentifier "com.example.QRScreenScanner.test"
defaults write "$(pwd)/test_build/app/QR Scanner.app/Contents/Info" CFBundleName "QR Scanner Test"

# Create a script to open the modified app
cat > test_build/run_test.sh << EOF
#!/bin/bash
echo "Starting QR Scanner Test App..."
open "$(pwd)/test_build/app/QR Scanner.app"
echo "App started. Please test the QR code scanning and result visibility."
echo "When finished, run: killall 'QR Scanner' to close the app."
EOF

chmod +x test_build/run_test.sh

echo "=== Setup Complete ==="
echo "To test the app, run: ./test_build/run_test.sh"
echo "This will start a copy of the app for testing."
echo "When you're finished testing, run: killall 'QR Scanner' to close the app."
echo ""
echo "NOTE: Since we can't directly modify the compiled Swift code in the app, this test version"
echo "will still have the original visibility issue. If you want to test with the fixed version,"
echo "please use the test_view/index.html page to see how the fix will look when implemented."
echo ""
echo "Would you like to run the test app now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    ./test_build/run_test.sh
fi 