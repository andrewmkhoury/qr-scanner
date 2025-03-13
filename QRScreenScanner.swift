import SwiftUI
import Vision
import AppKit
import Cocoa
import Carbon.HIToolbox
import AVFoundation
// We're now using the QRCodeGeneratorView from the separate file

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

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var smartModeController: SmartModeController?
    private var debugMode = false // Default to false, will check command line args
    
    // Add a property to store the QR code window reference
    var qrCodeWindow: NSWindow?
    
    // Add a property to store the QR code generator window reference
    private var qrGeneratorWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for debug flag in command line arguments
        debugMode = CommandLine.arguments.contains("--debug")
        
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
            if debugMode {
                print("Using system QR code icon for status bar")
            }
            
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
        menu.addItem(NSMenuItem(title: "Scan for QR Codes", action: #selector(scanQRCodeAction), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Create QR Code", action: #selector(createQRCode), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Set the application icon for dock and Command+Tab switcher
        setApplicationIcon()
    }
    
    @objc func statusItemClicked() {
        // Directly scan for QR codes when the status item is clicked
        scanQRCodeAction()
        
        if debugMode {
            print("Status item clicked, initiating QR code scan")
        }
    }
    
    @objc func scanQRCodeAction() {
        if debugMode {
            print("Scan QR Codes action triggered")
        }
        
        // Call the main scan function
        scanForQRCodes()
    }
    
    func scanForQRCodes() {
        if debugMode {
            print("=== DEBUG: scanForQRCodes called ===")
            print("Thread is main: \(Thread.isMainThread)")
        }
        
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.scanForQRCodes()
            }
            return
        }
        
        // *********************
        // CRITICAL FIX: Always reset the entire application state before scanning
        // This is a "nuclear option" but should prevent segmentation faults
        // *********************
        emergencyReset()
        
        // After the emergency reset, wait a moment then continue with a clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.debugMode {
                print("Continuing with scan after emergency reset")
            }
            self.startFreshScan()
        }
    }
    
    // Update the startFreshScan method with extra safeguards
    private func startFreshScan() {
        if debugMode {
            print("Starting fresh scan with clean state")
            print("SmartModeController: \(String(describing: smartModeController))")
        }
        
        // Double-check SmartModeController is null
        if smartModeController != nil {
            if debugMode {
                print("WARNING: SmartModeController still exists after reset - clearing it")
            }
            smartModeController = nil
        }
        
        if debugMode {
            print("Creating new SmartModeController")
        }
        
        // Create controller with debug flag
        let newController = SmartModeController(debugMode: debugMode)
        
        if debugMode {
            print("Successfully created SmartModeController")
        }
        
        // Store reference
        smartModeController = newController
        
        // Set up callback
        if debugMode {
            print("Setting up QR code detection callback")
        }
        
        smartModeController?.onQRCodeDetected = { [weak self] payload in
            guard let self = self else {
                print("ERROR: Self is nil in QR code detection callback")
                return
            }
            
            if self.debugMode {
                print("QR code detected with payload: \(payload)")
            }
            
            // Handle QR code
            self.handleQRCode(payload)
        }
        
        // Start scanning with a delay for safety
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let controller = self.smartModeController else {
                print("ERROR: Controller was deallocated before scanning could start")
                return
            }
            
            if self.debugMode {
                print("Starting smart mode scanning")
            }
            
            // Toggle smart mode
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
            // Safely stop the controller
            DispatchQueue.main.async {
            controller.stopSmartMode()
                print("Smart mode controller stopped")
                
                // Set to nil after stopping to prevent any callbacks
            self.smartModeController = nil
                
                // Show the QR code window after controller is stopped
                DispatchQueue.main.async {
                    self.showQRCodeWindow(with: localPayload)
                }
            }
        } else {
            // No controller to stop, show window directly
            showQRCodeWindow(with: localPayload)
        }
    }
    
    // MARK: - Window Management
    // Centralized window creation method
    private func createWindow(withTitle title: String, size: NSSize) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0, 
                y: 0, 
                width: size.width, 
                height: size.height
            ),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.center()
        window.isReleasedWhenClosed = false // We'll handle this manually
        window.delegate = self
        
        if debugMode {
            print("Created window: \(title)")
        }
        
        return window
    }
    
    // Safe cleanup method for any window
    private func safelyCleanupWindow(_ window: NSWindow) {
        if debugMode {
            print("Safely cleaning up window: \(window.title)")
        }
        
        // First disable all interaction with the window
        window.ignoresMouseEvents = true
        
        // Cleanup content view to break retain cycles
        if let contentView = window.contentView {
            // Remove all control actions
            for subview in contentView.subviews {
                if let control = subview as? NSControl {
                    control.target = nil
                    control.action = nil
                }
                // Remove from superview
                subview.removeFromSuperview()
            }
        }
        
        // Replace with empty view
        window.contentView = NSView(frame: NSRect.zero)
        
        // Order out (hide) the window
        window.orderOut(nil)
    }
    
    // QR Code Generator Window Management
    @objc func createQRCode() {
        if debugMode {
            print("=== DEBUG: createQRCode called ===")
            print("Thread is main: \(Thread.isMainThread)")
        }
        
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.createQRCode()
            }
            return
        }
        
        // If we already have a QR generator window visible, just bring it to front
        if let existingWindow = qrGeneratorWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // First ensure any previous window is fully cleaned up
        if let oldWindow = qrGeneratorWindow {
            safelyCleanupWindow(oldWindow)
            oldWindow.close()
            qrGeneratorWindow = nil
        }
        
        // Create new window
        let window = createWindow(
            withTitle: "Create QR Code",
            size: NSSize(width: 400, height: 500)
        )
        
        // Create and configure the SwiftUI hosting view
        let qrView = QRCodeGeneratorView()
        let hostingView = NSHostingView(rootView: qrView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        hostingView.autoresizingMask = [.width, .height]
        
        // Set the hosting view as the content
        window.contentView = hostingView
        
        // Store reference
        qrGeneratorWindow = window
        
        // Show window with animation
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        })
    }
    
    // QR Scan Result Window Management
    func showQRCodeWindow(with payload: String) {
        if debugMode {
            print("Creating QR code result window for payload: \(payload)")
        }
        
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.showQRCodeWindow(with: payload)
            }
            return
        }
        
        // Clean up any existing window
        if let oldWindow = qrCodeWindow {
            safelyCleanupWindow(oldWindow)
            oldWindow.close()
            qrCodeWindow = nil
        }
        
        // Define window dimensions
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 450
        
        // Create new window
        let window = createWindow(
            withTitle: "QR Code Detected",
            size: NSSize(width: windowWidth, height: windowHeight)
        )
        
        // Create and configure the result view
        let resultView = ResultView(result: payload)
        let hostingView = NSHostingView(rootView: resultView)
        hostingView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        window.level = .floating
        
        // Store reference
        qrCodeWindow = window
        
        // Show with animation
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        })
    }
    
    // MARK: - NSWindowDelegate Implementation
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if debugMode {
            print("=== DEBUG: windowShouldClose called ===")
            print("Window title: \(sender.title)")
        }
        
        // Determine which window is closing
        if sender === qrGeneratorWindow {
            if debugMode {
                print("QR Generator window closing")
            }
            
            // Clean up window
            safelyCleanupWindow(sender)
            
            // Clear reference
            qrGeneratorWindow = nil
            
            if debugMode {
                print("QR Generator window cleanup complete")
            }
        }
        else if sender === qrCodeWindow {
            if debugMode {
                print("QR Code result window closing")
            }
            
            // Clean up smart mode controller
            if let controller = smartModeController {
                controller.stopSmartMode()
                smartModeController = nil
            }
            
            // Clean up window
            safelyCleanupWindow(sender)
            
            // Clear reference
            qrCodeWindow = nil
            
            if debugMode {
                print("QR Code result window cleanup complete")
            }
        }
        
        // Return true to allow the window to close
        return true
    }
    
    // Called after the window is closed
    func windowWillClose(_ notification: Notification) {
        if debugMode {
            print("Window will close notification received")
        }
        
        // No need to do anything here - everything is handled in windowShouldClose
    }
    
    // Set the application icon for dock and Command+Tab switcher
    private func setApplicationIcon() {
        // For a menu bar app to show in dock, we need to change the activation policy
        NSApp.setActivationPolicy(.regular)

        // Try to load the app icon from various locations
        var appIcon: NSImage? = nil

        // First prioritize the appicon.png that's used in the dialogs for consistency
        if let iconPath = Bundle.main.path(forResource: "appicon", ofType: "png") {
            appIcon = NSImage(contentsOfFile: iconPath)
            if debugMode {
                print("Loaded cute app icon from appicon.png")
            }
        }

        // If PNG not found in main bundle resources, try application directory
        if appIcon == nil {
            let projectDir = FileManager.default.currentDirectoryPath
            let iconPath = projectDir + "/appicon.png"
            if FileManager.default.fileExists(atPath: iconPath) {
                appIcon = NSImage(contentsOfFile: iconPath)
                if debugMode {
                    print("Loaded cute app icon from project directory: \(iconPath)")
                }
            }
        }

        // Fall back to AppIcon.icns if appicon.png not found
        if appIcon == nil, let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            appIcon = NSImage(contentsOfFile: iconPath)
            if debugMode {
                print("Loaded app icon from AppIcon.icns")
            }
        }

        // If still no icon found, use the system QR code symbol
        if appIcon == nil, let qrSymbol = NSImage(systemSymbolName: "qrcode", accessibilityDescription: "QR Scanner") {
            // Use the system symbol directly without modification
            appIcon = qrSymbol
            
            if debugMode {
                print("Using system QR code symbol for application icon as last resort")
            }
        }

        // If an icon was found, set it as the application icon
        if let icon = appIcon {
            // Important: Don't set as template image for application icon
            icon.isTemplate = false
            
            // Resize to appropriate icon size
            let iconSize: CGFloat = 128  // Standard application icon size
            let resizedIcon = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { rect in
                icon.draw(in: rect)
                return true
            }

            NSApp.applicationIconImage = resizedIcon
            if debugMode {
                print("Set application icon for dock and Command+Tab switcher")
            }
        } else if debugMode {
            print("Could not find application icon")
            
            // Print bundle paths for debugging
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Resource path: \(Bundle.main.resourcePath ?? "nil")")
        }
    }

    // Update the emergency reset method to use our improved window cleanup method
    private func emergencyReset() {
        if debugMode {
            print("=== EMERGENCY RESET INITIATED ===")
            print("Performing complete application state reset")
            print("Current SmartModeController: \(String(describing: smartModeController))")
        }
        
        // Instead of cleaning up QR Generator window, just store a reference to it if it exists
        var preservedQRGeneratorWindow: NSWindow? = nil
        if let window = qrGeneratorWindow {
            if debugMode {
                print("Preserving QR Generator window during reset")
            }
            // Save the window reference to restore it after reset
            preservedQRGeneratorWindow = window
        } else {
            if debugMode {
                print("QR Generator window was already nil")
            }
        }
        
        // Temporarily remove reference (will restore if needed)
        qrGeneratorWindow = nil
        
        // Clean up SmartModeController
        if let controller = smartModeController {
            if debugMode {
                print("Stopping SmartModeController during emergency reset")
            }
            
            controller.stopSmartMode()
            smartModeController = nil
            
            if debugMode {
                print("SmartModeController stopped during emergency reset")
            }
        } else {
            if debugMode {
                print("No SmartModeController to clean up")
            }
        }
        
        // Restore QR Generator window reference if it was preserved
        if let preservedWindow = preservedQRGeneratorWindow {
            if debugMode {
                print("Restoring QR Generator window after reset")
            }
            qrGeneratorWindow = preservedWindow
        }
        
        if debugMode {
            print("Emergency reset complete")
            print("SmartModeController after reset: \(String(describing: smartModeController))")
            print("QR Generator window after reset: \(String(describing: qrGeneratorWindow))")
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