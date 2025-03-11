import SwiftUI

struct ResultView: View {
    let result: String
    @State private var isCopied = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var qrImage: NSImage?
    
    private var isURL: Bool {
        if let url = URL(string: result), url.scheme != nil {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Add the cute QR code character at the top
            Group {
                if let image = qrImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 85, height: 85)
                } else {
                    // Fallback to system QR code icon if appicon.png is not available
                    Image(systemName: "qrcode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 85, height: 85)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("QR Code Content")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                Text(result)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                
                HStack {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                        isCopied = true
                        
                        // Reset the copied state after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    }) {
                        Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    if isURL {
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: result) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("Open URL", systemImage: "safari")
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                if isURL {
                    LinkPreview(urlString: result)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(width: 320)
        }
        .frame(width: 350)
        .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95))
        .onAppear {
            loadQRImage()
        }
    }
    
    private func loadQRImage() {
        // Try to load the app icon from various locations
        
        // Try bundle resources first
        if let iconPath = Bundle.main.path(forResource: "appicon", ofType: "png"),
           let loadedImage = NSImage(contentsOfFile: iconPath) {
            self.qrImage = loadedImage
            return
        }
        
        // Try bundle path
        if let loadedImage = NSImage(contentsOfFile: Bundle.main.bundlePath + "/Contents/Resources/appicon.png") {
            self.qrImage = loadedImage
            return
        }
        
        // Try current directory
        if let projectPath = FileManager.default.currentDirectoryPath as String?,
           let loadedImage = NSImage(contentsOfFile: projectPath + "/appicon.png") {
            self.qrImage = loadedImage
            return
        }
        
        // Try to load directly from the bundle
        if let loadedImage = NSImage(named: "appicon") {
            self.qrImage = loadedImage
            return
        }
        
        // Fallback to system icon
        if let loadedImage = NSImage(named: "qrcode") {
            self.qrImage = loadedImage
            return
        }
    }
}

struct LinkPreview: View {
    let urlString: String
    @State private var title: String = "Loading preview..."
    @State private var faviconImage: NSImage?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let image = faviconImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(.primary)
                        .frame(width: 16, height: 16)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text(urlString)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(white: 0.15) : Color.secondary.opacity(0.1))
        .onAppear {
            loadWebsiteInfo()
        }
    }
    
    private func loadWebsiteInfo() {
        guard let url = URL(string: urlString) else { return }
        
        // In a real app, you would fetch the website title and favicon
        // For this example, we'll just use the domain name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.title = url.host ?? "Website"
        }
    }
}

// Add a cute QR code character view
struct QRCodeCharacter: View {
    var body: some View {
        Image("appicon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 85, height: 85)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResultView(result: "https://www.apple.com")
                .frame(width: 350, height: 400)
                .previewDisplayName("URL Result")
                .environment(\.colorScheme, .light)
            
            ResultView(result: "https://www.apple.com")
                .frame(width: 350, height: 400)
                .previewDisplayName("URL Result (Dark)")
                .environment(\.colorScheme, .dark)
            
            ResultView(result: "Just some plain text from a QR code")
                .frame(width: 350, height: 400)
                .previewDisplayName("Text Result")
                .environment(\.colorScheme, .light)
            
            ResultView(result: "Just some plain text from a QR code")
                .frame(width: 350, height: 400)
                .previewDisplayName("Text Result (Dark)")
                .environment(\.colorScheme, .dark)
        }
    }
} 