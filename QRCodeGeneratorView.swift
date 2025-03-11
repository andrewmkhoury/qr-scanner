import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    @State private var inputText: String = ""
    @State private var qrCodeImage: NSImage? = nil
    @State private var isImageGenerated = false
    @State private var errorMessage: String? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 20) {
            // App icon and title at the top
            Image("appicon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .padding(.top, 10)
            
            Text("Create QR Code")
                .font(.headline)
                .padding(.bottom, 10)
            
            // Text input field
            VStack(alignment: .leading) {
                Text("Enter text or URL:")
                    .font(.subheadline)
                
                TextEditor(text: $inputText)
                    .frame(height: 100)
                    .padding(5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Generate button
            Button(action: generateQRCode) {
                Text("Generate QR Code")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(inputText.isEmpty)
            
            // Display error message if any
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // QR code display area
            if isImageGenerated, let image = qrCodeImage {
                VStack {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(colorScheme == .dark ? Color.white : Color.white)
                        .cornerRadius(10)
                    
                    // Save image button
                    Button(action: saveQRCodeImage) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save QR Code")
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 400, minHeight: 450)
    }
    
    private func generateQRCode() {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter text to generate a QR code"
            return
        }
        
        errorMessage = nil
        
        // Generate QR code
        let data = Data(inputText.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            // Scale the image to make it larger
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            // Create a CIImage with a white background for better visibility
            let backgroundImage = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: scaledImage.extent)
            let combinedImage = scaledImage.composited(over: backgroundImage)
            
            if let cgImage = context.createCGImage(combinedImage, from: combinedImage.extent) {
                qrCodeImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                isImageGenerated = true
            } else {
                errorMessage = "Failed to generate QR code image"
            }
        } else {
            errorMessage = "Failed to generate QR code"
        }
    }
    
    private func saveQRCodeImage() {
        guard let image = qrCodeImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "QRCode.png"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        try pngData.write(to: url)
                    }
                } catch {
                    errorMessage = "Error saving image: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct QRCodeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeGeneratorView()
    }
} 