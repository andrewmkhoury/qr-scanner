import SwiftUI
import Vision
import AppKit
import Cocoa
import Carbon.HIToolbox
import AVFoundation

struct QRScreenScanner: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Add a property to store the QR code window reference
    @State private var qrCodeWindow: NSWindow?
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var smartModeController: SmartModeController?
    private let debugMode = true // Enable debug mode for additional logging
    
    // Add a property to store the QR code window reference
    var qrCodeWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if debugMode {
            print("Application did finish launching with debug mode enabled")
        }
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to load the custom QR code character icon for the status bar
            var statusBarIcon: NSImage? = nil
            
            // Use system QR code icon
            statusBarIcon = NSImage(systemSymbolName: "qrcode", accessibilityDescription: "QR Scanner")
            print("Using system QR code icon for status bar")
            
            // Resize the image to fit in the status bar (16x16 or 18x18 is typical)
            if statusBarIcon != nil {
                let statusBarSize: CGFloat = 18
                let resizedIcon = NSImage(size: NSSize(width: statusBarSize, height: statusBarSize), flipped: false) { rect in
                    statusBarIcon?.draw(in: rect)
                    return true
                }
                
                // Use template mode for proper appearance in light/dark mode
                resizedIcon.isTemplate = true
                button.image = resizedIcon
            }
            
            button.action = #selector(statusItemClicked)
            button.target = self
            
            if debugMode {
                print("Status bar item created successfully")
            }
        }
        
        // Set up the menu for right-click
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Scan for QR Codes", action: #selector(statusItemClicked), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Create QR Code", action: #selector(createQRCode), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func statusItemClicked() {
        // Directly scan for QR codes when the status item is clicked
        scanForQRCodes()
        
        if debugMode {
            print("Status item clicked, scanning for QR codes")
        }
    }
    
    func scanForQRCodes() {
        if debugMode {
            print("scanForQRCodes called")
        }
        
        // First, set a flag to indicate we're in the process of scanning
        let isRescanning = smartModeController != nil
        
        // Clean up any existing smart mode controller
        if let controller = smartModeController {
            if debugMode {
                print("Stopping existing smart mode controller")
            }
            
            // Make sure we properly clean up the controller
            // Use a local reference to avoid potential nil issues during cleanup
            let localController = controller
            
            // First set our reference to nil to prevent any callbacks
            smartModeController = nil
            
            // Then stop the controller on the main thread
            DispatchQueue.main.async {
                localController.stopSmartMode()
                print("Existing controller stopped")
            }
            
            // Small delay to ensure cleanup is complete - increased to 0.3 seconds
            Thread.sleep(forTimeInterval: 0.3)
            print("Cleanup delay completed")
        }
        
        // Create a new controller
        let newController = SmartModeController()
        
        // Store the controller reference before setting up callbacks
        smartModeController = newController
        
        if debugMode {
            print("Created new SmartModeController")
            smartModeController?.testCallback() // Test if callback is working
        }
        
        // Use strong reference to self to ensure the controller isn't deallocated
        smartModeController?.onQRCodeDetected = { [self] payload in
            if self.debugMode {
                print("QR code callback triggered with payload: \(payload)")
            }
            // Capture self strongly to ensure the controller stays alive
            self.handleQRCode(payload)
        }
        
        if debugMode {
            print("Set onQRCodeDetected callback")
            smartModeController?.testCallback() // Test again after setting callback
        }
        
        // Ensure we're on the main thread when toggling smart mode
        // Add a small delay if we're rescanning to ensure previous cleanup is complete
        let delay = isRescanning ? 0.2 : 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, let controller = self.smartModeController else {
                print("Controller was deallocated before activation")
                return
            }
            
            print("Smart mode toggled on")
            controller.toggleSmartMode()
            
            if self.debugMode {
                print("Smart mode toggled on")
            }
        }
    }
    
    // Direct method to show an alert without any callbacks or cleanup
    func showDirectAlert(title: String, message: String) {
        print("showDirectAlert called with title: \(title), message: \(message)")
        
        // Create and configure the alert
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        
        // Ensure we're on the main thread
        if Thread.isMainThread {
            print("Showing direct alert on main thread")
            alert.runModal()
            print("Direct alert closed")
        } else {
            print("Dispatching direct alert to main thread")
            DispatchQueue.main.async {
                alert.runModal()
                print("Direct alert closed (from background thread)")
            }
        }
    }
    
    func handleQRCode(_ payload: String) {
        // Handle QR code here by displaying a window
        print("QR Code detected in AppDelegate: \(payload)")
        
        // Make sure we're on the main thread for UI operations
        if !Thread.isMainThread {
            print("WARNING: handleQRCode called from background thread, dispatching to main thread")
            DispatchQueue.main.async {
                self.handleQRCode(payload)
            }
            return
        }
        
        if debugMode {
            print("handleQRCode running on main thread for payload: \(payload)")
        }
        
        // Store the payload locally to avoid any reference issues
        let localPayload = String(payload)
        
        // Clean up the smart mode controller first to prevent any callbacks during window operations
        if let controller = self.smartModeController {
            print("Stopping smart mode controller")
            controller.stopSmartMode()
            self.smartModeController = nil
        }
        
        // Show the QR code window after cleanup
        showQRCodeWindow(with: localPayload)
    }
    
    func showQRCodeWindow(with payload: String) {
        print("Creating QR code window for payload: \(payload)")
        
        // Create a window with more modern dimensions
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 400  // Adjusted width for the updated ResultView
        let windowHeight: CGFloat = 450  // Adjusted height for the updated ResultView with character
        
        let windowRect = NSRect(
            x: (screenRect.width - windowWidth) / 2,
            y: (screenRect.height - windowHeight) / 2,
            width: windowWidth,
            height: windowHeight
        )
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // Set up window delegate to handle the close button in the title bar
        window.delegate = self
        
        window.title = "QR Code Detected"
        window.isReleasedWhenClosed = true
        
        // Use system background color for proper dark mode support
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Respect system appearance setting
        window.appearance = NSAppearance.current
        
        // Create SwiftUI ResultView and host it in the window
        let resultView = ResultView(result: payload)
        let hostingView = NSHostingView(rootView: resultView)
        hostingView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        
        // Add subtle animation when showing the window
        window.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        })
        
        // Store the window reference
        self.qrCodeWindow = window
    }
    
    @objc func closeQRCodeWindow(_ sender: NSButton) {
        print("Close button clicked, attempting to close window safely")
        
        // Create a local reference to the window to avoid any reference issues
        guard let windowRef = sender.window else {
            print("Warning: Close button clicked but window reference is nil")
            return
        }
        
        // Store a weak reference to avoid retain cycles
        weak var weakWindow = windowRef
        
        // First, remove all targets and actions from buttons to prevent callbacks
        if let contentView = windowRef.contentView {
            for subview in contentView.subviews {
                if let button = subview as? NSButton {
                    button.target = nil
                    button.action = nil
                }
            }
        }
        
        // Use orderOut instead of close to avoid potential segmentation faults
        DispatchQueue.main.async {
            print("Ordering window out from main thread")
            weakWindow?.orderOut(nil)
            
            // Release the window after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("Window closed successfully")
                // Set window to nil to ensure it's deallocated
                if weakWindow != nil {
                    print("Window reference still exists after closing")
                } else {
                    print("Window reference has been properly released")
                }
            }
        }
    }
    
    @objc func openURL(_ sender: NSButton) {
        guard let window = sender.window else {
            print("Warning: Open URL button clicked but window reference is nil")
            return
        }
        
        guard let contentView = window.contentView else {
            print("Warning: Window content view is nil")
            return
        }
        
        // First try to get the payload field by tag
        var payloadField = contentView.viewWithTag(100) as? NSTextField
        
        // If not found by tag, try by identifier
        if payloadField == nil {
            payloadField = contentView.subviews.first(where: { $0.identifier?.rawValue == "payload" }) as? NSTextField
        }
        
        guard let field = payloadField, !field.stringValue.isEmpty else {
            print("Failed to get payload for URL opening")
            return
        }
        
        let payload = field.stringValue
        print("Preparing to open URL: \(payload)")
        
        // First close the window to avoid any interaction with it
        window.orderOut(nil)
        
        // Create a local copy of the URL string
        let urlString = String(payload)
        
        // Detach completely from the window and use a new task
        DispatchQueue.global(qos: .userInitiated).async {
            // Wait a moment to ensure window is gone
            Thread.sleep(forTimeInterval: 0.5)
            
            // Then dispatch back to main for UI work
            DispatchQueue.main.async {
                if let url = URL(string: urlString) {
                    print("Opening URL in separate process: \(url)")
                    
                    // Use a Process to open the URL instead of NSWorkspace
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = [url.absoluteString]
                    
                    do {
                        try task.run()
                        print("URL opened successfully via process")
                    } catch {
                        print("Error opening URL via process: \(error)")
                        
                        // Fallback to NSWorkspace as a last resort
                        print("Trying NSWorkspace as fallback")
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    @objc func copyToClipboard(_ sender: NSButton) {
        guard let window = sender.window else {
            print("Warning: Copy button clicked but window reference is nil")
            return
        }
        
        guard let contentView = window.contentView else {
            print("Warning: Window content view is nil")
            return
        }
        
        // First try to get the payload field by tag
        var payloadField = contentView.viewWithTag(100) as? NSTextField
        
        // If not found by tag, try by identifier
        if payloadField == nil {
            payloadField = contentView.subviews.first(where: { $0.identifier?.rawValue == "payload" }) as? NSTextField
        }
        
        guard let field = payloadField, !field.stringValue.isEmpty else {
            print("Failed to get payload for clipboard")
            return
        }
        
        let payload = field.stringValue
        print("Copying to clipboard: \(payload)")
        
        // First hide the window to avoid interaction with it
        window.orderOut(nil)
        
        // Create a local copy of the payload
        let localPayload = String(payload)
        
        // Copy to clipboard on a slight delay to ensure window is gone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(localPayload, forType: .string)
            
            print("Copied to clipboard successfully")
            
            // No need to close the window as it's already ordered out
        }
    }
    
    @objc func createQRCode() {
        if debugMode {
            print("Create QR Code menu item clicked")
        }
        
        // Check if a window already exists and just bring it forward
        if let existingWindow = qrCodeWindow, existingWindow.isVisible {
            print("Using existing QR Code window")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        } else if let existingWindow = qrCodeWindow {
            print("Existing window found but not visible - making visible")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        print("Creating new QR Code window")
        
        // Create and configure the QR code creation window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Create QR Code"
        window.center()
        
        // Essential: window must not be released when closed!
        window.isReleasedWhenClosed = false
        print("Setting isReleasedWhenClosed to false")
        
        // Configure window for proper keyboard input handling
        window.level = NSWindow.Level.floating  // Use floating level to keep it above other windows
        print("Setting window level to floating")
        
        // Configure window behavior to remain visible across spaces
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        print("Setting window collection behavior")
        
        // Make window delegate self to handle window closing
        window.delegate = self
        print("Window delegate set")
        
        // Use system background color for proper dark mode support
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Respect system appearance setting
        window.appearance = NSAppearance.current
        
        print("Creating QRCodeGeneratorView")
        
        // Create SwiftUI QRCodeGenerator view and host it in the window
        let qrCodeGeneratorView = QRCodeGeneratorView()
        print("QRCodeGeneratorView created successfully")
        
        let hostingView = NSHostingView(rootView: qrCodeGeneratorView)
        print("NSHostingView created successfully")
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 450)
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        print("ContentView set successfully")
        
        // Store the window reference before making it visible
        self.qrCodeWindow = window
        print("Window reference stored")
        
        window.makeKeyAndOrderFront(nil)
        print("Window ordered front")
        
        NSApp.activate(ignoringOtherApps: true)
        print("App activated")
        
        // After a brief delay, bring the window to front and activate input again
        // This helps ensure the window remains visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("Executing delayed window activation")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            print("Delayed activation complete")
            
            // Additional activation to ensure window stays in front
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()  // More forceful ordering to front
                NSApp.activate(ignoringOtherApps: true)
                print("Extra activation complete - window should be visible now")
            }
        }
    }
}

// MARK: - QR Code Detection Extension
extension AppDelegate {
    func detectQRCode(in image: CGImage) -> [String] {
        let request = VNDetectBarcodesRequest()
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try requestHandler.perform([request])
            
            // Get the results as [VNObservation]? (the actual type)
            guard let observations = request.results else {
                print("No results from barcode detection")
                return []
            }
            
            // Directly use observations as they are already VNBarcodeObservation
            let barcodeObservations = observations
            
            var payloads: [String] = []
            
            for barcode in barcodeObservations {
                // Check if it's a QR code with a payload
                if barcode.symbology == .qr, let payload = barcode.payloadStringValue {
                    // Add a new copy of the payload string
                    payloads.append(String(payload))
                }
            }
            
            print("Detected \(payloads.count) QR code payloads")
            return payloads
        } catch {
            print("Failed to perform QR code detection: \(error)")
            return []
        }
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("Window should close delegate method called for: \(sender.title)")
        
        // Special handling for QR Code generator window
        if sender.title == "Create QR Code" {
            print("QR Code generator window - keeping window alive")
            
            // Just hide the window instead of closing it
            sender.orderOut(nil)
            
            // Return false to prevent the standard close behavior
            return false
        }
        
        // For other windows, proceed with normal closure handling
        print("Standard window closing procedure")
        
        // Get a strong reference to content view and all subviews
        if let contentView = sender.contentView {
            // Disable all interactive elements first
            for subview in contentView.subviews {
                if let button = subview as? NSButton {
                    print("Removing button target and action")
                    button.target = nil
                    button.action = nil
                } else if let control = subview as? NSControl {
                    print("Disabling control")
                    control.isEnabled = false
                }
            }
        }
        
        // Use orderOut instead of close to avoid the close animation
        // that might trigger the segmentation fault
        DispatchQueue.main.async {
            print("Ordering window out instead of closing")
            sender.orderOut(nil)
            
            // Create a timer to finish cleanup after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Final cleanup completed")
            }
        }
        
        // Return false to prevent the standard close behavior
        // We'll handle closing ourselves with orderOut
        return false
    }
    
    // This method was getting called but might be triggering the crash
    // Keep it for diagnostics but make it do minimal work
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            print("Window will close notification received - window not found")
            return
        }
        
        print("Window will close notification received for: \(window.title)")
        
        // Special handling for QR Code generator window
        if window.title == "Create QR Code" {
            print("QR Code generator window closing - will be preserved for reuse")
        }
    }
} 