import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

// NSTextField wrapper for better input handling
struct MacOSTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isMultiline: Bool = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Basic configuration
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = NSColor.labelColor
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Initialize with the current text or placeholder
        if !text.isEmpty {
            textView.string = text
        } else {
            textView.string = placeholder
            textView.textColor = NSColor.placeholderTextColor
            context.coordinator.isShowingPlaceholder = true
        }
        
        // Set up scrolling
        scrollView.hasVerticalScroller = isMultiline
        scrollView.hasHorizontalScroller = false
        
        // Ensure the text view becomes first responder when its window appears
        DispatchQueue.main.async {
            if let window = textView.window {
                window.makeFirstResponder(textView)
                print("Set textView as first responder")
            } else {
                print("No window available for first responder")
            }
        }
        
        // Add notification observer for when the window becomes key
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if the text has changed from an external source
        // and we're not showing a placeholder
        if textView.string != text && !context.coordinator.isShowingPlaceholder {
            textView.string = text
        }
        
        // Try to make the text view first responder
        if let window = scrollView.window, window.isKeyWindow {
            window.makeFirstResponder(textView)
        }
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        // Remove notification observer
        NotificationCenter.default.removeObserver(coordinator)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, placeholder: placeholder)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var placeholder: String
        var isShowingPlaceholder = false
        weak var textView: NSTextView?
        
        init(text: Binding<String>, placeholder: String) {
            self.text = text
            self.placeholder = placeholder
            super.init()
        }
        
        // Handle window becoming key
        @objc func windowDidBecomeKey(_ notification: Notification) {
            guard let window = notification.object as? NSWindow,
                  let scrollView = window.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView,
                  let textView = scrollView.documentView as? NSTextView else {
                return
            }
            
            // When our window becomes key, make the text view first responder
            DispatchQueue.main.async {
                window.makeFirstResponder(textView)
                print("Window became key, setting textView as first responder")
            }
        }
        
        // Handle click or tab into the text field
        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.textView = textView
            
            // Clear placeholder when editing begins
            if isShowingPlaceholder {
                textView.string = ""
                textView.textColor = NSColor.labelColor
                isShowingPlaceholder = false
            }
            
            // Ensure keyboard focus
            DispatchQueue.main.async {
                if let window = textView.window {
                    window.makeFirstResponder(textView)
                }
                NSApp.activate(ignoringOtherApps: true)
                print("Text editing began, ensured text view is first responder")
            }
        }
        
        // Handle text changes
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update the binding with the new text
            isShowingPlaceholder = false
            self.text.wrappedValue = textView.string
        }
    }
}

struct QRCodeGeneratorView: View {
    @State private var inputText: String = ""
    @State private var qrCodeImage: NSImage? = nil
    @State private var isImageGenerated = false
    @State private var errorMessage: String? = nil
    @State private var showCopyFeedback: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 20) {
            // App icon and title at the top
            Image(systemName: "qrcode")
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
                
                // Use our custom MacOSTextField for reliable input handling
                MacOSTextField(text: $inputText, placeholder: "Enter text or URL", isMultiline: true)
                    .frame(height: 100)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        // Set focus after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
            }
            .padding(.horizontal)
            
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
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        // Copy image button
                        Button(action: copyQRCodeImage) {
                            HStack {
                                Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                                Text(showCopyFeedback ? "Copied!" : "Copy")
                            }
                            .padding()
                            .background(showCopyFeedback ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Save image button
                        Button(action: saveQRCodeImage) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
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
    
    private func copyQRCodeImage() {
        guard let image = qrCodeImage else { return }
        
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