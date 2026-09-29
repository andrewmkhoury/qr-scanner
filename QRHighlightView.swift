import Cocoa

// MARK: - QR Highlight View
class QRHighlightView: NSView {
    private var animationTimer: Timer?
    var payload: String = ""
    var onMouseClick: ((String) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        print("QRHighlightView.mouseDown called with payload: \(payload)")
        
        // Store the callback locally to prevent any potential memory issues
        let callback = onMouseClick
        let payloadCopy = payload
        
        // Execute the callback on the main thread
        DispatchQueue.main.async {
            print("QR code clicked: \(payloadCopy)")
            callback?(payloadCopy)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.push()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.pop()
    }

    deinit {
        animationTimer?.invalidate()
        onMouseClick = nil
    }

    private func startAnimation() {
        guard animationTimer == nil else { return }

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw a more prominent highlight around the QR code
        let highlightColor = NSColor.systemGreen.withAlphaComponent(0.3)
        highlightColor.set()
        bounds.fill()
        
        // Draw a thick border
        let borderColor = NSColor.systemGreen
        borderColor.set()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
        path.lineWidth = 3.0
        path.stroke()
        
        // Add corner markings
        let cornerSize: CGFloat = min(bounds.width, bounds.height) * 0.2
        let padding: CGFloat = 2.0
        
        NSColor.white.set()
        
        // Draw corners
        drawCorner(at: NSPoint(x: padding, y: padding), cornerSize: cornerSize, orientation: .topLeft)
        drawCorner(at: NSPoint(x: bounds.width - padding, y: padding), cornerSize: cornerSize, orientation: .topRight)
        drawCorner(at: NSPoint(x: padding, y: bounds.height - padding), cornerSize: cornerSize, orientation: .bottomLeft)
        drawCorner(at: NSPoint(x: bounds.width - padding, y: bounds.height - padding), cornerSize: cornerSize, orientation: .bottomRight)
        
        // Animate border with smoother pulsing
        let time = Date().timeIntervalSince1970
        let alpha = 0.5 + 0.3 * sin(time * 2.0)
        
        NSColor.systemGreen.withAlphaComponent(CGFloat(alpha)).set()
        let animatedPath = NSBezierPath(rect: bounds)
        animatedPath.lineWidth = 2.0
        animatedPath.stroke()
    }
    
    private enum CornerOrientation {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    private func drawCorner(at point: NSPoint, cornerSize: CGFloat, orientation: CornerOrientation) {
        let path = NSBezierPath()
        path.lineWidth = 2.0
        
        switch orientation {
        case .topLeft:
            path.move(to: NSPoint(x: point.x, y: point.y + cornerSize))
            path.line(to: NSPoint(x: point.x, y: point.y))
            path.line(to: NSPoint(x: point.x + cornerSize, y: point.y))
        case .topRight:
            path.move(to: NSPoint(x: point.x - cornerSize, y: point.y))
            path.line(to: NSPoint(x: point.x, y: point.y))
            path.line(to: NSPoint(x: point.x, y: point.y + cornerSize))
        case .bottomLeft:
            path.move(to: NSPoint(x: point.x, y: point.y - cornerSize))
            path.line(to: NSPoint(x: point.x, y: point.y))
            path.line(to: NSPoint(x: point.x + cornerSize, y: point.y))
        case .bottomRight:
            path.move(to: NSPoint(x: point.x - cornerSize, y: point.y))
            path.line(to: NSPoint(x: point.x, y: point.y))
            path.line(to: NSPoint(x: point.x, y: point.y - cornerSize))
        }
        
        path.stroke()
    }
} 