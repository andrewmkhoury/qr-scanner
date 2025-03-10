import SwiftUI

struct ResultView: View {
    let result: String
    @State private var isCopied = false
    
    private var isURL: Bool {
        if let url = URL(string: result), url.scheme != nil {
            return true
        }
        return false
    }
    
    var body: some View {
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
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
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
        .preferredColorScheme(.light)
    }
}

struct LinkPreview: View {
    let urlString: String
    @State private var title: String = "Loading preview..."
    @State private var faviconImage: NSImage?
    
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
                        .frame(width: 16, height: 16)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text(urlString)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
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

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResultView(result: "https://www.apple.com")
                .frame(width: 320, height: 240)
                .previewDisplayName("URL Result")
            
            ResultView(result: "Just some plain text from a QR code")
                .frame(width: 320, height: 240)
                .previewDisplayName("Text Result")
        }
    }
} 