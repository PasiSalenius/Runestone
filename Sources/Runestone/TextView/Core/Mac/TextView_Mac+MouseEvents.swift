#if os(macOS)
import AppKit

public extension TextView {
    /// Informs the receiver that the user has pressed the left mouse button.
    /// - Parameter event: An object encapsulating information about the mouse-down event.
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let location = locationClosestToPoint(in: event)

        // Check for Shift modifier to extend selection
        if event.modifierFlags.contains(.shift) {
            // Shift is held: always extend selection, regardless of click count
            extendSelectionOnShiftClick(to: location)
            // Start autoscroll timer so user can continue dragging to extend further
            startAutoscrollTimer()
        } else {
            if event.clickCount == 1 {
                textViewController.move(to: location)
                textViewController.startDraggingSelection(from: location)
                startAutoscrollTimer()
            } else if event.clickCount == 2 {
                textViewController.selectWord(at: location)
            } else if event.clickCount == 3 {
                textViewController.selectLine(at: location)
            }
        }
    }

    /// Informs the receiver that the user has moved the mouse with the left button pressed.
    /// - Parameter event: An object encapsulating information about the mouse-dragged event.
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        let location = locationClosestToPoint(in: event)
        textViewController.extendDraggedSelection(to: location)
        // Store the current mouse event for autoscrolling
        currentDragEvent = event
        // Trigger immediate autoscroll when mouse moves
        scrollContentView.autoscroll(with: event)
    }

    /// Informs the receiver that the user has released the left mouse button.
    /// - Parameter event: An object encapsulating information about the mouse-up event.
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        stopAutoscrollTimer()
        if event.clickCount == 1 {
            let location = locationClosestToPoint(in: event)
            textViewController.extendDraggedSelection(to: location)
        }
    }

    /// Informs the receiver that the user has pressed the right mouse button.
    /// - Parameter event: An object encapsulating information about the mouse-down event.
    override func rightMouseDown(with event: NSEvent) {
        let location = locationClosestToPoint(in: event)
        if let selectedRange = textViewController.selectedRange, !selectedRange.contains(location) || textViewController.selectedRange == nil {
            textViewController.selectWord(at: location)
        }
        super.rightMouseDown(with: event)
    }

    // MARK: - Shift+Click Selection

    private func extendSelectionOnShiftClick(to clickLocation: Int) {
        guard let currentRange = textViewController.selectedRange else {
            // No existing selection, just move cursor
            textViewController.move(to: clickLocation)
            return
        }

        // Determine anchor point (where selection started)
        // If there's a selection, anchor is at the opposite end from where we're extending
        let anchor: Int
        if currentRange.length == 0 {
            // Zero-length selection: anchor is current position
            anchor = currentRange.location
        } else {
            // Determine which end is closer to the click
            let distanceToStart = abs(clickLocation - currentRange.location)
            let distanceToEnd = abs(clickLocation - currentRange.upperBound)

            // Anchor at the opposite end
            anchor = distanceToStart < distanceToEnd ? currentRange.upperBound : currentRange.location
        }

        // Create new selection from anchor to click location
        let newRange: NSRange
        if clickLocation >= anchor {
            newRange = NSRange(location: anchor, length: clickLocation - anchor)
        } else {
            newRange = NSRange(location: clickLocation, length: anchor - clickLocation)
        }

        textViewController.selectedRange = newRange

        // Update selection origin so that if user continues dragging,
        // it extends from the correct anchor point (like TextEdit)
        textViewController.updateDragOrigin(to: anchor)
    }
}

private extension TextView {

    private func locationClosestToPoint(in event: NSEvent) -> Int {
        let point = scrollContentView.convert(event.locationInWindow, from: nil)
        return characterIndex(for: point)
    }

    private func startAutoscrollTimer() {
        // Invalidate any existing timer
        stopAutoscrollTimer()
        // Create a timer that fires periodically to enable continuous autoscrolling
        // when the mouse is held outside the visible area (not moving)
        autoscrollTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            self?.performAutoscroll()
        }
    }

    private func stopAutoscrollTimer() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
        currentDragEvent = nil
    }

    private func performAutoscroll() {
        // Call autoscroll with the last mouse event
        // This enables continuous scrolling when mouse is held still outside visible area
        if let event = currentDragEvent {
            scrollContentView.autoscroll(with: event)
        }
    }
}
#endif
