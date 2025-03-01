import Cocoa
import Vision
import CoreGraphics
import UserNotifications

class SmartModeController: NSObject {
    private var isActive = false
    private var timer: Timer?
    private var qrWindow: NSWindow?
    private var qrHighlightWindows: [NSWindow] = []
    private var qrCodeLocations: [String: CGRect] = [:]
    private var qrCodesList: [String] = []
    private var globalClickMonitor: Any?
    var onQRCodeDetected: ((String) -> Void)?
    
    func toggleSmartMode() {
        print("Toggle smart mode called, current state: \(isActive ? "active" : "inactive")")
        
        // If we're already active, stop first
        if isActive {
            stopSmartMode()
            // Ensure we're fully stopped before toggling
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Toggle the state
        isActive = !isActive
        
        if isActive {
            print("Starting smart mode")
            startSmartMode()
        } else {
            print("Smart mode toggled off")
        }
    }
    
    func startSmartMode() {
        print("Starting smart mode initialization")
        
        // Make sure we're active
        guard isActive else {
            print("Cannot start smart mode - controller is not active")
            return
        }
        
        // Clear any existing data
        qrCodeLocations.removeAll()
        qrCodesList.removeAll()
        
        // Clear any existing highlights on the main thread
        if Thread.isMainThread {
            clearHighlights()
        } else {
            DispatchQueue.main.sync {
                self.clearHighlights()
            }
        }
        
        // Remove any existing global click monitor
        if let monitor = globalClickMonitor {
            print("Removing existing global click monitor during initialization")
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        
        // Only scan the screen when Smart Mode is activated
        print("Initialization complete, scanning screen")
        scanScreen()
    }
    
    func stopSmartMode() {
        print("Stopping smart mode - cleaning up resources")
        
        // Deactivate first to prevent further scanning
        isActive = false
        
        // Clear data structures immediately to prevent access to stale data
        qrCodeLocations.removeAll()
        qrCodesList.removeAll()
        
        // Remove click monitor on the main thread
        if let monitor = globalClickMonitor {
            print("Removing global click monitor")
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        
        // Perform UI cleanup on main thread
        if Thread.isMainThread {
            performUICleanup()
        } else {
            DispatchQueue.main.sync {
                self.performUICleanup()
            }
        }
        
        // Wait a moment to ensure cleanup is complete
        Thread.sleep(forTimeInterval: 0.1)
        
        print("Smart mode stopped and resources cleaned up")
    }
    
    private func setupGlobalClickMonitor() {
        // Remove existing monitor if any
        if let monitor = globalClickMonitor {
            print("Removing existing global click monitor")
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        
        print("Setting up new global click monitor")
        
        // Create a weak reference to self to avoid retain cycles
        weak var weakSelf = self
        
        // Use a local variable to store the monitor before assigning to the property
        let newMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { event in
            // Get strong reference to self
            guard let strongSelf = weakSelf, strongSelf.isActive else { 
                print("SmartModeController is no longer active or has been deallocated")
                return 
            }
            
            print("Global click detected at: \(NSEvent.mouseLocation)")
            
            // Get the actual global mouse location for more accurate detection
            let mouseLocation = NSEvent.mouseLocation
            var clickedOnQRCode = false
            var clickedPayload: String?
            
            // Create a local copy of the QR code locations to avoid memory issues
            let localQRCodeLocations = strongSelf.qrCodeLocations
            
            // Check if click is in any of our tracked QR code locations
            for (payload, rect) in localQRCodeLocations {
                if rect.contains(mouseLocation) {
                    clickedOnQRCode = true
                    clickedPayload = String(payload) // Create a local copy
                    print("Click detected inside QR code: \(payload)")
                    break
                }
            }
            
            if clickedOnQRCode, let payload = clickedPayload {
                print("Processing click on QR code: \(payload)")
                // Dispatch to main thread
                DispatchQueue.main.async {
                    // Check again if self is still active
                    guard let strongSelf = weakSelf, strongSelf.isActive else { return }
                    
                    print("Handling QR code click on main thread")
                    // Stop highlighting when a QR code is clicked
                    strongSelf.clearHighlights()
                    strongSelf.handleQRCodeSelected(payload)
                }
            }
        }
        
        // Assign the monitor to the property
        globalClickMonitor = newMonitor
        
        print("Global click monitor set up")
    }
    
    private func createQRWindow() {
        // Create a simple window for displaying detected QR codes
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 400
        
        let windowRect = NSRect(
            x: screenRect.maxX - windowWidth - 20,
            y: screenRect.maxY - windowHeight - 20,
            width: windowWidth,
            height: windowHeight
        )
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "QR Scanner - Smart Mode"
        window.isReleasedWhenClosed = false
        
        // Create the main content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        
        // Create a label to show instructions
        let label = NSTextField(frame: NSRect(x: 15, y: windowHeight - 40, width: windowWidth - 30, height: 30))
        label.stringValue = "QR Codes detected on screen will appear here:"
        label.isEditable = false
        label.isBordered = false
        label.isSelectable = false
        label.backgroundColor = .clear
        label.font = NSFont.systemFont(ofSize: 13)
        contentView.addSubview(label)
        
        // Create a scroll view to display QR codes
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 50, width: windowWidth - 20, height: windowHeight - 100))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        let clipView = NSClipView()
        scrollView.contentView = clipView
        
        let tableView = NSTableView()
        tableView.autoresizingMask = [.width]
        tableView.headerView = nil
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("QRCode"))
        column.width = scrollView.frame.width - 20
        tableView.addTableColumn(column)
        
        // Set delegate and data source
        tableView.delegate = self
        tableView.dataSource = self
        
        scrollView.documentView = tableView
        contentView.addSubview(scrollView)
        
        // Add a close button
        let closeButton = NSButton(frame: NSRect(x: (windowWidth - 100) / 2, y: 15, width: 100, height: 30))
        closeButton.title = "Stop Smart Mode"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        contentView.addSubview(closeButton)
        
        window.contentView = contentView
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        
        qrWindow = window
    }
    
    @objc private func closeButtonClicked() {
        toggleSmartMode()
    }
    
    private func scanScreen() {
        // Make sure we're active before proceeding
        guard isActive else {
            print("Scan screen called but controller is not active, aborting")
            return
        }
        
        print("Starting screen scan")
        
        // Clear previous data on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isActive else { 
                print("Controller no longer active during data clearing")
                return 
            }
            self.qrCodeLocations.removeAll()
            self.qrCodesList.removeAll()
            self.clearHighlights()
            print("Previous data cleared")
        }
        
        // Get a screenshot of the main display
        guard let screenshot = CGDisplayCreateImage(CGMainDisplayID()) else {
            print("Failed to create screenshot")
            return
        }
        
        // Create a local copy of the screenshot to avoid memory issues
        let localScreenshot = screenshot
        
        // Process QR codes synchronously to avoid memory issues
        let request = VNDetectBarcodesRequest()
        let requestHandler = VNImageRequestHandler(cgImage: localScreenshot, options: [:])
        
        do {
            try requestHandler.perform([request])
            
            // Check if we're still active after the request
            guard isActive else {
                print("Controller no longer active after barcode detection")
                return
            }
            
            guard let results = request.results else {
                print("No results from barcode detection")
                
                // Don't set up the global click monitor when no QR codes are found
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isActive else { 
                        print("Controller no longer active during UI update (no results)")
                        return 
                    }
                    print("No QR codes found on screen")
                }
                return
            }
            
            // Process detected QR codes
            var detectedQRCodes: [(payload: String, rect: CGRect)] = []
            
            // Filter and process QR codes
            for observation in results {
                // Check if it's a barcode observation with QR code data
                let barcode = observation
                if barcode.symbology == .qr, 
                   let payload = barcode.payloadStringValue {
                    // Create a local copy of the payload
                    let localPayload = String(payload)
                    
                    // Get the bounding box in normalized coordinates
                    let boundingBox = barcode.boundingBox
                    
                    // Get the main screen for coordinate conversion
                    guard let mainScreen = NSScreen.main else { 
                        print("Could not get main screen")
                        continue 
                    }
                    
                    // Get the screen frame in Cocoa coordinates (origin at bottom-left)
                    let screenFrame = mainScreen.frame
                    
                    // Convert Vision coordinates (normalized 0-1, origin at bottom-left) to screen coordinates
                    // Note: Vision's coordinate system has (0,0) at bottom-left, same as Cocoa
                    let x = boundingBox.origin.x * screenFrame.width
                    let y = boundingBox.origin.y * screenFrame.height
                    let width = boundingBox.width * screenFrame.width
                    let height = boundingBox.height * screenFrame.height
                    
                    // Add padding around the QR code
                    let padding: CGFloat = 5
                    let rect = NSRect(
                        x: x - padding,
                        y: y - padding,
                        width: width + (padding * 2),
                        height: height + (padding * 2)
                    ).integral
                    
                    detectedQRCodes.append((payload: localPayload, rect: rect))
                }
            }
            
            // Check if we're still active before updating UI
            guard isActive else {
                print("Controller no longer active before UI update")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isActive else { 
                    print("SmartModeController is no longer active, skipping UI update")
                    return 
                }
                
                // Update the list and create highlights
                self.qrCodesList = detectedQRCodes.map { $0.payload }
                
                // Create a local copy of the QR code locations to avoid memory issues
                var localQRCodeLocations = [String: CGRect]()
                
                for qrCode in detectedQRCodes {
                    // Store in local dictionary first
                    localQRCodeLocations[qrCode.payload] = qrCode.rect
                    // Then update the instance variable
                    self.qrCodeLocations[qrCode.payload] = qrCode.rect
                    // Create highlight window
                    self.createHighlightWindow(at: qrCode.rect, for: qrCode.payload)
                }
                
                // If no QR codes were found, show a notification
                if detectedQRCodes.isEmpty {
                    print("No QR codes found on screen")
                } else {
                    print("Found \(detectedQRCodes.count) QR codes and created highlights")
                    // Only setup global monitor when QR codes are actually detected
                    self.setupGlobalClickMonitor()
                }
            }
            
        } catch {
            print("Failed to perform QR code detection: \(error)")
        }
    }
    
    private func showNotification(message: String) {
        // This method is no longer used due to bundle issues with UNUserNotificationCenter
        print("Notification: \(message)")
        
        // Instead of using UNUserNotificationCenter which requires proper bundle setup,
        // we'll just log the message to the console
        
        /* 
        // Original implementation that was causing crashes:
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Request permission if needed
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else {
                if let error = error {
                    print("Notification authorization denied: \(error.localizedDescription)")
                }
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "QR Code Scanner"
            content.body = message
            content.sound = UNNotificationSound.default
        */
    }
    
    private func updateQRCodesList() {
        guard let window = qrWindow, 
              let contentView = window.contentView,
              let scrollView = contentView.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView,
              let tableView = scrollView.documentView as? NSTableView else {
            return
        }
        
        // Reload the table view data
        tableView.reloadData()
    }
    
    private func updateHighlights(_ qrCodes: [(rect: CGRect, payload: String)]) {
        // Clear existing highlights first
        clearHighlights()
        
        // Create new highlights
        for qrCode in qrCodes {
            createHighlightWindow(at: qrCode.rect, for: qrCode.payload)
        }
    }
    
    private func clearHighlights() {
        assert(Thread.isMainThread, "clearHighlights must be called on main thread")
        
        // Close all highlight windows
        for window in qrHighlightWindows {
            window.orderOut(nil)
        }
        // Clear the array after all windows are ordered out
        qrHighlightWindows.removeAll()
    }
    
    private func createHighlightWindow(at rect: CGRect, for payload: String) {
        assert(Thread.isMainThread, "createHighlightWindow must be called on main thread")
        
        // Make sure we're still active
        guard isActive else {
            print("Attempted to create highlight window while inactive")
            return
        }
        
        // Make sure the rectangle is valid and has a minimum size
        let safeRect = NSRect(
            x: max(0, rect.origin.x),
            y: max(0, rect.origin.y),
            width: max(30, rect.width),
            height: max(30, rect.height)
        ).integral
        
        // Create a borderless window
        let highlightWindow = NSWindow(
            contentRect: safeRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        highlightWindow.level = .floating
        highlightWindow.backgroundColor = .clear
        highlightWindow.isOpaque = false
        highlightWindow.isReleasedWhenClosed = false
        highlightWindow.ignoresMouseEvents = false
        highlightWindow.hasShadow = false
        highlightWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        highlightWindow.alphaValue = 1.0
        
        // Create a local copy of the payload to avoid any memory issues
        let payloadCopy = String(payload)
        
        // Create and configure the highlight view
        let highlightView = QRHighlightView(frame: NSRect(origin: .zero, size: safeRect.size))
        highlightView.payload = payloadCopy
        
        // Weak reference to self to avoid retain cycles
        weak var weakSelf = self
        
        // Set up the click handler with a weak-strong pattern
        highlightView.onMouseClick = { _ in
            // Get strong reference to self
            guard let strongSelf = weakSelf, strongSelf.isActive else {
                print("SmartModeController is no longer active during click handling")
                return
            }
            
            print("Highlight window clicked for QR code: \(payloadCopy)")
            strongSelf.handleQRCodeSelected(payloadCopy)
        }
        
        highlightWindow.contentView = highlightView
        
        // Store the window and show it
        qrHighlightWindows.append(highlightWindow)
        highlightWindow.orderFrontRegardless()
        
        print("Created highlight window for QR code: \(payloadCopy) at \(safeRect)")
    }
    
    // Handle QR code selection
    private func handleQRCodeSelected(_ payload: String) {
        print("handleQRCodeSelected called with payload: \(payload)")
        
        // Store a local reference to the callback before deactivating
        let callback = self.onQRCodeDetected
        
        // Deactivate smart mode first to prevent further scanning
        self.isActive = false
        
        // Clean up resources before showing the alert
        self.clearHighlights()
        
        // Use the main thread for UI operations
        if !Thread.isMainThread {
            print("WARNING: handleQRCodeSelected called from background thread, dispatching to main thread")
            DispatchQueue.main.async {
                self.handleQRCodeSelected(payload)
            }
            return
        }
        
        if let callbackFn = callback {
            print("Using callback function for QR code: \(payload)")
            // If we have a callback, use it and let the AppDelegate handle the UI
            callbackFn(payload)
            print("Callback function called for QR code: \(payload)")
        } else {
            print("No callback set, showing alert directly for QR code: \(payload)")
            // Create a custom alert with app icon
            let alert = NSAlert()
            alert.messageText = "QR Code Detected"
            alert.informativeText = payload
            
            // Try to load the app icon
            if let iconPath = Bundle.main.path(forResource: "appicon", ofType: "png"),
               let iconImage = NSImage(contentsOfFile: iconPath) {
                alert.icon = iconImage
            } else {
                // Fallback to default system icon
                alert.icon = NSImage(named: NSImage.infoName)
            }
            
            // Add buttons
            alert.addButton(withTitle: "Close")
            
            if let url = URL(string: payload), (payload.hasPrefix("http://") || payload.hasPrefix("https://")) {
                alert.addButton(withTitle: "Open URL")
                alert.addButton(withTitle: "Copy to Clipboard")
                
                let response = alert.runModal()
                print("Alert response: \(response.rawValue)")
                
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(url)
                } else if response == .alertThirdButtonReturn {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(payload, forType: .string)
                }
            } else {
                alert.addButton(withTitle: "Copy to Clipboard")
                
                let response = alert.runModal()
                print("Alert response: \(response.rawValue)")
                
                if response == .alertSecondButtonReturn {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(payload, forType: .string)
                }
            }
            
            // Play a success sound
            NSSound.beep()
        }
        
        print("QR Code detection handling completed for: \(payload)")
        
        // Ensure we stop smart mode completely
        self.stopSmartMode()
    }
    
    deinit {
        print("SmartModeController deinit called")
        
        // Ensure proper cleanup
        if isActive {
            print("Controller is still active during deinit, stopping smart mode")
            isActive = false // Set to false first to prevent any new operations
            
            // Remove any global monitors immediately
            if let monitor = globalClickMonitor {
                if Thread.isMainThread {
                    NSEvent.removeMonitor(monitor)
                } else {
                    DispatchQueue.main.sync {
                        NSEvent.removeMonitor(monitor)
                    }
                }
                globalClickMonitor = nil
                print("Global monitor removed during deinit")
            }
            
            // Clear data structures
            qrCodeLocations.removeAll()
            qrCodesList.removeAll()
        }
        
        // Clean up any remaining windows on the main thread - use dispatch_sync to ensure completion
        if Thread.isMainThread {
            self.performUICleanup()
            print("UI cleanup completed during deinit")
        } else {
            DispatchQueue.main.sync {
                self.performUICleanup()
                print("UI cleanup completed during deinit (from background thread)")
            }
        }
        
        print("SmartModeController deinit complete")
    }
    
    private func performUICleanup() {
        assert(Thread.isMainThread, "performUICleanup must be called on main thread")
        
        // Close all windows
        if let window = qrWindow {
            print("Closing QR window")
            window.orderOut(nil)
            qrWindow = nil
        }
        
        print("Clearing highlight windows")
        clearHighlights()
    }
}

// MARK: - NSTableView Delegate & DataSource

extension SmartModeController: NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return qrCodesList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < qrCodesList.count else {
            return nil
        }
        
        let payload = qrCodesList[row]
        let cellIdentifier = NSUserInterfaceItemIdentifier("QRCodeCell")
        
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            if let textField = cell.textField {
                textField.stringValue = payload
            }
            return cell
        }
        
        // Create a new cell
        let cell = NSTableCellView()
        cell.identifier = cellIdentifier
        
        // Create text field for the payload
        let textField = NSTextField(frame: NSRect(x: 5, y: 5, width: tableView.bounds.width - 85, height: 20))
        textField.stringValue = payload
        textField.isEditable = false
        textField.isBordered = false
        textField.isSelectable = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.backgroundColor = .clear
        cell.addSubview(textField)
        cell.textField = textField
        
        // Add a select button
        let button = NSButton(frame: NSRect(x: tableView.bounds.width - 75, y: 2, width: 70, height: 25))
        button.title = "Select"
        button.bezelStyle = .rounded
        button.tag = row
        button.target = self
        button.action = #selector(selectQRCode(_:))
        cell.addSubview(button)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
    
    @objc private func selectQRCode(_ sender: NSButton) {
        let row = sender.tag
        guard row < qrCodesList.count else {
            return
        }
        
        let payload = qrCodesList[row]
        handleQRCodeSelected(payload)
    }
    
    func windowWillClose(_ notification: Notification) {
        if isActive {
            toggleSmartMode()
        }
    }
}

// MARK: - QR Highlight View
// QRHighlightView class has been moved to QRHighlightView.swift

// Add this extension to check if the AppDelegate is properly handling QR code detection
extension SmartModeController {
    // This method will be called from the AppDelegate to test if the callback is working
    func testCallback() {
        print("SmartModeController.testCallback() called")
        if onQRCodeDetected == nil {
            print("WARNING: onQRCodeDetected callback is nil!")
        } else {
            print("onQRCodeDetected callback is properly set")
        }
    }
} 