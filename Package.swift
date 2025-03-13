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
                "BUILD.md",
                "QRScreenScanner_v1.0.0.dmg",
                "QRScreenScanner_v1.0.1.dmg",
                "QRScreenScanner_v1.0.3.dmg",
                "QRScreenScanner_v1.0.4.dmg",
                "update_version.sh",
                "Config",
            ],
            resources: [
                .process("AppIcon.icns"),
                .process("appicon.png")
            ]
        ),
    ]
) 