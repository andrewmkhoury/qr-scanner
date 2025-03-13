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
    private var debugMode = false
    
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
                    strongSelf.handleQRCodeSelected(payload: payload)
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
        // Skip if we're no longer active
        if !isActive {
            if debugMode {
                print("Scan screen called but controller is not active, aborting")
            }
            return
        }
        
        if debugMode {
            print("Starting screen scan")
        }
        
        // Clear previous data
        qrCodesList.removeAll()
        qrCodeLocations.removeAll()
        
        // Clear previous highlights on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.sync { [weak self] in
                guard let self = self, self.isActive else {
                    if self?.debugMode == true {
                        print("Controller no longer active during data clearing")
                    }
                    return
                }
                
                self.clearHighlights()
            }
        } else {
            clearHighlights()
        }
        
        if debugMode {
            print("Previous data cleared")
        }
        
        // Take screenshot
        guard let cgImage = createScreenshot() else {
            if debugMode {
                print("Failed to create screenshot")
            }
            return
        }
        
        // Detect QR codes in the screenshot
        detectQRCodes(in: cgImage)
    }
    
    private func createScreenshot() -> CGImage? {
        if debugMode {
            print("Taking screenshot of main screen")
        }
        
        // Get the main display ID
        let displayID = CGMainDisplayID()
        
        // Create a screenshot of the entire screen
        guard let screenshot = CGDisplayCreateImage(displayID) else {
            if debugMode {
                print("Failed to create screenshot")
            }
            return nil
        }
        
        if debugMode {
            print("Screenshot captured successfully")
        }
        
        return screenshot
    }
    
    private func detectQRCodes(in image: CGImage) {
        // Run Vision request to detect barcodes
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            // Access results on main thread to update UI
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isActive else {
                    if self?.debugMode == true {
                        print("Controller no longer active after barcode detection")
                    }
                    return
                }
                
                guard let observations = request.results else {
                    if self.debugMode {
                        print("No results from barcode detection")
                    }
                    
                    // Update UI to indicate no results
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.isActive else {
                            if self?.debugMode == true {
                                print("Controller no longer active during UI update (no results)")
                            }
                            return
                        }
                        
                        if self.debugMode {
                            print("No QR codes found on screen")
                        }
                    }
                    return
                }
                
                // Process QR code results - Using the approach from v1.0.1
                var detectedQRCodes: [(rect: CGRect, payload: String)] = []
                var localQRCodesList: [String] = []
                var localQRCodeLocations: [String: CGRect] = [:]
                
                // Get the main screen for coordinate conversion
                guard let mainScreen = NSScreen.main else {
                    if self.debugMode {
                        print("Failed to get main screen")
                    }
                    return
                }
                
                let screenFrame = mainScreen.frame
                
                for observation in observations {
                    guard let barcodeObservation = observation as? VNBarcodeObservation,
                          barcodeObservation.symbology == .qr,
                          let payload = barcodeObservation.payloadStringValue else {
                        continue
                    }
                    
                    // Make a local copy of the payload string
                    let payloadCopy = String(payload)
                    
                    if self.debugMode {
                        print("QR code found with payload: \(payloadCopy)")
                        print("Original bounding box: \(barcodeObservation.boundingBox)")
                    }
                    
                    // Get the bounding box in normalized coordinates
                    let boundingBox = barcodeObservation.boundingBox
                    
                    // Vision framework provides normalized coordinates (0,0 at bottom left, 1,1 at top right)
                    // Convert to screen coordinates (origin at bottom-left)
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
                    
                    if self.debugMode {
                        print("Final screen rect: \(rect)")
                    }
                    
                    // Store the QR code information
                    detectedQRCodes.append((rect: rect, payload: payloadCopy))
                    localQRCodesList.append(payloadCopy)
                    localQRCodeLocations[payloadCopy] = rect
                    
                    if self.debugMode {
                        print("QR code at screen position: \(rect)")
                    }
                }
                
                // Update QR code data
                self.qrCodesList = localQRCodesList
                self.qrCodeLocations = localQRCodeLocations
                
                if self.debugMode {
                    print("Found \(localQRCodesList.count) QR codes on screen")
                }
                
                // Update UI with highlights if we found any QR codes
                if !detectedQRCodes.isEmpty {
                    self.updateHighlights(detectedQRCodes)
                    self.updateQRCodesList()
                    
                    // Setup global click monitor after finding QR codes
                    self.setupGlobalClickMonitor()
                }
            }
        } catch {
            if debugMode {
                print("Failed to perform QR code detection: \(error)")
            }
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
            strongSelf.handleQRCodeSelected(payload: payloadCopy)
        }
        
        highlightWindow.contentView = highlightView
        
        // Store the window and show it
        qrHighlightWindows.append(highlightWindow)
        highlightWindow.orderFrontRegardless()
        
        print("Created highlight window for QR code: \(payloadCopy) at \(safeRect)")
    }
    
    // Handle QR code selection
    private func handleQRCodeSelected(payload: String) {
        if debugMode {
            print("handleQRCodeSelected called with payload: \(payload)")
        }
        
        // Ensure we're on main thread for UI operations
        if !Thread.isMainThread {
            if debugMode {
                print("WARNING: handleQRCodeSelected called from background thread, dispatching to main thread")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.handleQRCodeSelected(payload: payload)
            }
            return
        }
        
        // Make a local copy of the payload
        let payloadCopy = String(payload)
        
        // If we have a callback registered, use it
        if let callback = onQRCodeDetected {
            if debugMode {
                print("Using callback function for QR code: \(payload)")
            }
            
            callback(payloadCopy)
            if debugMode {
                print("Callback function called for QR code: \(payload)")
            }
        } else {
            if debugMode {
                print("No callback set, showing alert directly for QR code: \(payload)")
            }
            
            // If no callback, show an alert directly
            showQRCodeAlert(payload: payloadCopy)
        }
        
        if debugMode {
            print("QR Code detection handling completed for: \(payload)")
        }
    }
    
    // Show an alert with the QR code payload
    private func showQRCodeAlert(payload: String) {
        if debugMode {
            print("Showing QR code alert for payload: \(payload)")
        }
        
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showQRCodeAlert(payload: payload)
            }
            return
        }
        
        // Create the alert
        let alert = NSAlert()
        alert.messageText = "QR Code Detected"
        alert.informativeText = "Content: \(payload)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy")
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        
        // Show the alert
        let response = alert.runModal()
        
        // Handle the user's choice
        switch response {
        case .alertFirstButtonReturn:
            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(payload, forType: .string)
            
            if debugMode {
                print("Copied QR code to clipboard: \(payload)")
            }
            
        case .alertSecondButtonReturn:
            // Try to open as URL
            if let url = URL(string: payload), url.scheme != nil {
                NSWorkspace.shared.open(url)
                
                if debugMode {
                    print("Opened URL from QR code: \(url)")
                }
            } else {
                // Not a valid URL, show error
                let errorAlert = NSAlert()
                errorAlert.messageText = "Invalid URL"
                errorAlert.informativeText = "The QR code content does not appear to be a valid URL."
                errorAlert.alertStyle = .warning
                errorAlert.addButton(withTitle: "OK")
                errorAlert.runModal()
                
                if debugMode {
                    print("Failed to open as URL: \(payload)")
                }
            }
            
        default:
            if debugMode {
                print("QR code alert dismissed: \(payload)")
            }
            break
        }
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
        handleQRCodeSelected(payload: payload)
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