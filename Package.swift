// swift-tools-version:5.3
import PackageDescription

// Helper function to generate shell script exclude list
func shellScripts() -> [String] {
    return [
        "create_icns.sh", 
        "build.sh",
        "repackage.sh",
        "repackage_pro.sh",
        "update_app.sh",
        "rebuild_test.sh",
        "rebuild_with_fix.sh",
        "test_app.sh",
        "build_app.sh",
        "create_simple_background.sh",
        "update_version.sh",
    ]
}

// Helper function to generate DMG exclude list
func dmgFiles() -> [String] {
    return [
        "QRScreenScanner.dmg",
        "QRScreenScanner_v1.0.0.dmg",
        "QRScreenScanner_v1.0.1.dmg",
        "QRScreenScanner_v1.0.3.dmg",
        "QRScreenScanner_v1.0.4.dmg",
    ]
}

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
                // Documentation files
                "README.md",
                "PACKAGING.md",
                "LICENSE",
                "BUILD.md",

                // Configuration files
                "Info.plist",
                "QRScreenScanner-Info.plist",

                // Asset files
                "AppIcon.iconset",
                "QRScanner-screenshot.png",

                // Project files
                "QRScreenScanner.xcodeproj",
                "docs",

                // Shell scripts
                "build.sh",
                "create_icns.sh",
                "create_simple_background.sh",
                "generate_exclude_list.sh",
                "repackage.sh",
                "repackage_pro.sh",
                "update_version.sh",

                // DMG files
                "QRScreenScanner_v1.0.0.dmg",
                "QRScreenScanner_v1.0.1.dmg",
                "QRScreenScanner_v1.0.4.dmg",

                // Directories
                "Config",
                "test_view",
                "QR Scanner.app",
                
                // Generated files
                "exclude_list.txt",
            ],
            resources: [
                .process("AppIcon.icns"),
                .process("appicon.png")
            ]
        ),
    ]
) 