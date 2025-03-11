#!/bin/bash

echo "=== Creating QR Code result test page ==="
mkdir -p test_view

# Create a test HTML page to simulate the result view
cat > test_view/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>QR Code Result Test</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: white;
            padding: 20px;
            max-width: 320px;
            margin: 0 auto;
        }
        .result-container {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .header {
            font-weight: bold;
            color: black;
            margin-bottom: 4px;
        }
        .content {
            font-family: monospace;
            color: black;
            background-color: rgb(242, 242, 242);
            padding: 8px;
            border-radius: 6px;
            border: 1px solid gray;
            line-height: 1.5;
        }
        .button-row {
            display: flex;
            gap: 10px;
        }
        .button {
            color: black;
            background: none;
            border: none;
            cursor: pointer;
            padding: 5px 10px;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .url-preview {
            background-color: rgb(242, 242, 242);
            padding: 12px;
            border-radius: 8px;
            border: 1px solid gray;
            margin-top: 10px;
        }
        .preview-title {
            font-weight: bold;
            color: black;
        }
        .preview-url {
            color: black;
            font-size: 12px;
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <div class="result-container">
        <div>
            <div class="header">QR Code Content</div>
            <div class="content">https://www.example.com/test-page?param=123&amp;other=456</div>
        </div>
        
        <div class="button-row">
            <button class="button">
                <span>📋</span> Copy
            </button>
            <button class="button" style="margin-left: auto;">
                <span>🌍</span> Open URL
            </button>
        </div>
        
        <div class="url-preview">
            <div class="preview-title">🌐 Website</div>
            <div class="preview-url">https://www.example.com/test-page?param=123&amp;other=456</div>
        </div>
    </div>
</body>
</html>
EOF

echo "=== Opening test page ==="
open test_view/index.html

echo "=== Test page created ==="
echo "If the text is clearly visible on this test page, we can apply the same styling to the Swift app." 