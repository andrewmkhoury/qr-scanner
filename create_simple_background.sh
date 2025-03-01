#!/bin/bash

# Script to create a simple background image for the DMG
# This is a fallback in case wkhtmltoimage or ImageMagick are not available

echo "Creating a simple background image for the DMG..."

# Create a simple HTML file
cat > simple_background.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #6e8efb, #a777e3);
            margin: 0;
            padding: 0;
            width: 600px;
            height: 400px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: white;
            text-align: center;
        }
        h1 {
            font-size: 32px;
            margin-bottom: 10px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        p {
            font-size: 16px;
            margin-top: 0;
            max-width: 80%;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
        }
        .instructions {
            margin-top: 40px;
            font-size: 14px;
            opacity: 0.9;
        }
        .arrow {
            font-size: 40px;
            margin: 20px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
    </style>
</head>
<body>
    <h1>QR Screen Scanner</h1>
    <p>Scan QR codes directly from your screen with ease</p>
    <div class="instructions">Drag the app to the Applications folder to install</div>
    <div class="arrow">→</div>
</body>
</html>
EOF

echo "HTML file created: simple_background.html"
echo ""
echo "To convert this to an image, you can:"
echo "1. Open the HTML file in a browser"
echo "2. Take a screenshot of the page"
echo "3. Save the screenshot as 'dmg_background.png'"
echo ""
echo "Or install one of these tools:"
echo "- wkhtmltoimage: brew install wkhtmltopdf"
echo "- ImageMagick: brew install imagemagick"
echo ""
echo "Then run the repackage_pro.sh script again."
echo ""
echo "Done!" 