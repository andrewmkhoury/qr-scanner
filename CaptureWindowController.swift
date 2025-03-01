import Cocoa

class CaptureWindowController: NSWindowController {
    var onRegionSelected: ((CGRect) -> Void)?
    private var selectionView: SelectionView?
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    
    override func loadWindow() {
        // Create a transparent window that covers the entire screen
        let screenRect = NSScreen.main?.frame ?? .zero
        let window = CaptureWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .statusBar
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create the selection view
        let selectionView = SelectionView(frame: screenRect)
        window.contentView = selectionView
        self.selectionView = selectionView
        
        self.window = window
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Register for mouse events on the window
        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .keyDown]
        NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            _ = self?.handleEvent(event)
            return event
        }
        
        // Show instruction label
        if let selectionView = self.selectionView {
            let label = NSTextField(labelWithString: "Drag to select the area containing a QR code, press Esc to cancel")
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.backgroundColor = NSColor.black.withAlphaComponent(0.7)
            label.alignment = .center
            label.isBezeled = false
            label.isEditable = false
            label.isSelectable = false
            
            selectionView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: selectionView.centerXAnchor),
                label.topAnchor.constraint(equalTo: selectionView.topAnchor, constant: 40),
                label.widthAnchor.constraint(lessThanOrEqualTo: selectionView.widthAnchor, constant: -40)
            ])
            
            // Add a subtle visual effect to make the window visible
            selectionView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        }
    }
    
    func handleEvent(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .leftMouseDown:
            startSelection(at: event.locationInWindow)
            
        case .leftMouseDragged:
            updateSelection(to: event.locationInWindow)
            
        case .leftMouseUp:
            endSelection(at: event.locationInWindow)
            
        case .keyDown:
            if event.keyCode == 53 { // ESC key
                cancelSelection()
            }
            
        default:
            break
        }
        
        return event
    }
    
    private func startSelection(at point: NSPoint) {
        startPoint = point
        currentRect = NSRect(x: point.x, y: point.y, width: 0, height: 0)
        selectionView?.selectionRect = currentRect
    }
    
    private func updateSelection(to point: NSPoint) {
        guard let startPoint = startPoint else { return }
        
        let origin = NSPoint(
            x: min(startPoint.x, point.x),
            y: min(startPoint.y, point.y)
        )
        
        let size = NSSize(
            width: abs(startPoint.x - point.x),
            height: abs(startPoint.y - point.y)
        )
        
        currentRect = NSRect(origin: origin, size: size)
        selectionView?.selectionRect = currentRect
    }
    
    private func endSelection(at point: NSPoint) {
        guard let currentRect = currentRect, currentRect.width > 10, currentRect.height > 10 else {
            // Selection too small, ignore
            cancelSelection()
            return
        }
        
        // Convert to screen coordinates
        let screenFrame = NSScreen.main?.frame ?? .zero
        let flippedRect = NSRect(
            x: currentRect.origin.x,
            y: screenFrame.height - currentRect.origin.y - currentRect.height,
            width: currentRect.width,
            height: currentRect.height
        )
        
        // Close the window and call the completion handler
        close()
        onRegionSelected?(flippedRect)
    }
    
    private func cancelSelection() {
        close()
    }
}

class CaptureWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class SelectionView: NSView {
    var selectionRect: NSRect? {
        didSet {
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.clear.set()
        dirtyRect.fill()
        
        guard let selectionRect = selectionRect else { return }
        
        // Draw semi-transparent overlay for the entire screen
        NSColor.black.withAlphaComponent(0.3).set()
        bounds.fill()
        
        // Clear the selection rectangle
        NSColor.clear.set()
        selectionRect.fill()
        
        // Draw border around selection
        NSColor.white.set()
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = 2.0
        path.stroke()
        
        // Draw magnifier at cursor location (to be implemented)
    }
} 