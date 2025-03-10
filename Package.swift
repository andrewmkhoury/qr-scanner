// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "QRScreenScanner",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "QRScreenScanner", targets: ["QRScreenScanner"]),
    ],
    dependencies: [
        // No external dependencies as we're using Apple's built-in frameworks
    ],
    targets: [
        .target(
            name: "QRScreenScanner",
            dependencies: [],
            path: ".",
            exclude: [
                "README.md", 
                "Info.plist", 
                "create_icns.sh", 
                "AppIcon.iconset", 
                "appicon.png",
                "docs",
                "QRScreenScanner.xcodeproj",
                "PACKAGING.md",
                "LICENSE",
                "QRScanner-screenshot.png",
                "QRScreenScanner-Info.plist",
                "test_view",
                "build.sh",
                "repackage.sh",
                "repackage_pro.sh",
                "update_app.sh",
                "rebuild_test.sh",
                "rebuild_with_fix.sh",
                "test_app.sh",
                "build_app.sh",
                "create_simple_background.sh",
                "QRScreenScanner.dmg",
                "BUILD.md"
            ],
            resources: [
                .process("AppIcon.icns")
            ]
        ),
    ]
) 