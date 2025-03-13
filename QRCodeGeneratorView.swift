import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    // MARK: - State
    @State private var inputText: String = ""
    @State private var qrCodeImage: NSImage? = nil
    @State private var isImageGenerated = false
    @State private var errorMessage: String? = nil
    @State private var showCopyFeedback: Bool = false
    @State private var appIconImage: NSImage? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Private properties
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    // MARK: - View Body
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            // Header with app icon and title
            headerView
                .padding(.top, 10)
            
            // Text input field
            inputFieldSection
            
            // Generate button
            generateButton
            
            // Error message if any
            errorView
            
            // Fixed height container for QR code area
            // This ensures layout doesn't shift when QR code appears
            ZStack(alignment: .top) {
                // Empty container when no QR code
                if !isImageGenerated {
                    Color.clear
                        .frame(height: 240)
                } else {
                    // QR code display area
                    qrCodeDisplaySection
                }
            }
            .frame(minHeight: 240)
            
            Spacer(minLength: 0) // Push content to top
        }
        .padding()
        .frame(minWidth: 350, idealWidth: 400, maxWidth: 450, minHeight: 600) // Increased height for better spacing
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadAppIcon()
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(spacing: 5) {
            // Use the same cute QR code character as in ResultView
            Group {
                if let iconImage = appIconImage {
                    Image(nsImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                } else {
                    // Fallback to system QR code icon if app icon is not available
                    Image(systemName: "qrcode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 5)
            
            Text("Create QR Code")
                .font(.headline)
                .padding(.bottom, 5)
        }
    }
    
    private var inputFieldSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Enter text or URL:")
                .font(.subheadline)
            
            TextEditor(text: $inputText)
                .frame(height: 80)
                .padding(5)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
    }

    private var generateButton: some View {
        Button(action: generateQRCode) {
            Text("Generate QR Code")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(inputText.isEmpty)
    }

    private var errorView: some View {
        Group {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.vertical, 2)
            } else {
                // Empty spacer when no error to maintain consistent layout
                Color.clear.frame(height: 2)
            }
        }
    }
    
    private var qrCodeDisplaySection: some View {
        VStack(spacing: 15) {
            // QR code display first
            Image(nsImage: qrCodeImage!)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color(NSColor.shadowColor).opacity(0.2), radius: 3, x: 0, y: 1)
            
            // Action buttons below
            HStack(spacing: 30) {
                // Copy button
                Button(action: copyQRCodeImage) {
                    HStack(spacing: 5) {
                        Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                        Text(showCopyFeedback ? "Copied!" : "Copy")
                    }
                    .frame(minWidth: 90)
                    .padding(.vertical, 6)
                    .background(showCopyFeedback ? Color.green.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Save button
                Button(action: saveQRCodeImage) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .frame(minWidth: 90)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isImageGenerated)
    }
    
    // MARK: - Functions
    
    private func generateQRCode() {
        // Validate input
        guard !inputText.isEmpty else {
            errorMessage = "Please enter text to generate a QR code"
            return
        }
        
        // Clear error message
        errorMessage = nil
        
        do {
            // Generate QR code
            let data = Data(inputText.utf8)
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel") // Higher correction level for better readability
            
            guard let outputImage = filter.outputImage else {
                throw NSError(domain: "QRCodeGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
            }
            
            // Use appropriate scale factor for clear QR code
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            // Create a white background for the QR code
            let backgroundImage = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
                .cropped(to: scaledImage.extent)
            
            // Composite the QR code over the white background
            let combinedImage = scaledImage.composited(over: backgroundImage)
            
            // Convert to CGImage with proper rendering
            guard let cgImage = context.createCGImage(combinedImage, from: combinedImage.extent) else {
                throw NSError(domain: "QRCodeGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
            }
            
            // Create NSImage directly from CGImage - simplified method
            qrCodeImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            // Update UI state
            isImageGenerated = true
            
        } catch {
            // Handle errors
            errorMessage = error.localizedDescription
            isImageGenerated = false
        }
    }
    
    private func copyQRCodeImage() {
        guard let image = qrCodeImage else { return }
        
        // Copy image to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        
        // Show feedback
        showCopyFeedback = true
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyFeedback = false
        }
    }
    
    private func saveQRCodeImage() {
        guard let image = qrCodeImage else { return }
        
        // Configure save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "QRCode.png"
        savePanel.message = "Choose a location to save your QR code"
        savePanel.prompt = "Save QR Code"
        
        // Show save panel
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                // Convert NSImage to PNG data
                if let tiffData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    
                    // Write to file
                    try pngData.write(to: url)
                } else {
                    throw NSError(domain: "QRCodeGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
                }
            } catch {
                // Handle save errors
                errorMessage = "Error saving image: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAppIcon() {
        // Try to load the app icon from various locations (same as ResultView)
        
        // Try bundle resources first
        if let iconPath = Bundle.main.path(forResource: "appicon", ofType: "png"),
           let loadedImage = NSImage(contentsOfFile: iconPath) {
            self.appIconImage = loadedImage
            return
        }
        
        // Try bundle path
        if let loadedImage = NSImage(contentsOfFile: Bundle.main.bundlePath + "/Contents/Resources/appicon.png") {
            self.appIconImage = loadedImage
            return
        }
        
        // Try current directory
        if let projectPath = FileManager.default.currentDirectoryPath as String?,
           let loadedImage = NSImage(contentsOfFile: projectPath + "/appicon.png") {
            self.appIconImage = loadedImage
            return
        }
        
        // Try to load directly from the bundle
        if let loadedImage = NSImage(named: "appicon") {
            self.appIconImage = loadedImage
            return
        }
    }
}

// MARK: - Previews
struct QRCodeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QRCodeGeneratorView()
                .previewDisplayName("Light Mode")
            
            QRCodeGeneratorView()
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 