// swift-tools-version:5.3
import PackageDescription
import Foundation

// Function to expand glob patterns to file lists
func expandGlob(pattern: String) -> [String] {
    let fileManager = FileManager.default
    let currentDirectory = fileManager.currentDirectoryPath
    
    do {
        // Get all files in the current directory
        let files = try fileManager.contentsOfDirectory(atPath: currentDirectory)
        
        // Use NSRegularExpression to match the pattern
        let regex: NSRegularExpression
        let patternString = pattern.replacingOccurrences(of: ".", with: "\\.")
                                   .replacingOccurrences(of: "*", with: ".*")
        do {
            regex = try NSRegularExpression(pattern: "^\(patternString)$", options: [])
        } catch {
            print("Error creating regex from pattern '\(pattern)': \(error)")
            return []
        }
        
        // Filter files that match the pattern
        let matchingFiles = files.filter { file in
            let range = NSRange(location: 0, length: file.utf16.count)
            return regex.firstMatch(in: file, options: [], range: range) != nil
        }
        
        return matchingFiles
    } catch {
        print("Error listing files: \(error)")
        return []
    }
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
                
                // Shell scripts - Using glob pattern
                ] + expandGlob(pattern: "*.sh") + [
                
                // DMG files - Using glob pattern
                ] + expandGlob(pattern: "QRScreenScanner*.dmg") + [
                
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