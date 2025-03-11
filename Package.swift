// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QRScreenScanner",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "QRScreenScanner",
            targets: ["QRScreenScanner"]),
    ],
    dependencies: [
        // No dependencies
    ],
    targets: [
        .target(
            name: "QRScreenScanner",
            dependencies: [],
            path: ".",
            exclude: [
                "README.md",
                "build.sh",
                "repackage.sh",
                "repackage_pro.sh",
                "create_simple_background.sh",
                "PACKAGING.md",
                "build_app.sh",
                "release_notes.md",
                "QR Scanner.app",
                "docs",
                ".build",
                "LICENSE",
                "rebuild_test.sh",
                "test_app.sh",
                "test_view",
                "BUILD.md",
                "AppIcon.iconset",
                "rebuild_with_fix.sh",
                "Info.plist",
                "QRScreenScanner-Info.plist",
                "QRScreenScanner_v1.0.0.dmg",
                "QRScreenScanner_v1.0.1.dmg",
                "QRScreenScanner_v1.0.2.dmg",
                "create_icns.sh",
                "QRScreenScanner.dmg",
                "update_app.sh",
                "Resources.bundle",
                "images"
            ],
            resources: [
                .process("Resources"),
                .process("AppIcon.icns")
            ]
        ),
    ]
) 