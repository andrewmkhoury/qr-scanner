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
                "*.sh",
                "QRScreenScanner*.dmg",
                "BUILD.md",
                "Config",
            ],
            resources: [
                .process("AppIcon.icns"),
                .process("appicon.png")
            ]
        ),
    ]
) 