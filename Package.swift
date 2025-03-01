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
            exclude: ["README.md", "Info.plist", "create_icns.sh", "AppIcon.iconset", "appicon.png"],
            resources: [
                .process("AppIcon.icns")
            ]
        ),
    ]
) 