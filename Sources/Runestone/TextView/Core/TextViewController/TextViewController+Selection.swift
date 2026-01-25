#if os(macOS)
import Foundation

extension TextViewController {
    func moveLeftAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .character, inDirection: .backward)
    }

    func moveRightAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .character, inDirection: .forward)
    }

    func moveUpAndModifySelection() {
        move(by: .line, inDirection: .backward)
    }

    func moveDownAndModifySelection() {
        move(by: .line, inDirection: .forward)
    }

    func moveWordLeftAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .word, inDirection: .backward)
    }

    func moveWordRightAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .word, inDirection: .forward)
    }

    func moveToBeginningOfLineAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .line, inDirection: .backward)
    }

    func moveToEndOfLineAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .line, inDirection: .forward)
    }

    func moveToBeginningOfParagraphAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .paragraph, inDirection: .backward)
    }

    func moveToEndOfParagraphAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .paragraph, inDirection: .forward)
    }

    func moveToBeginningOfDocumentAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .document, inDirection: .backward)
    }

    func moveToEndOfDocumentAndModifySelection() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .document, inDirection: .forward)
    }

    func startDraggingSelection(from location: Int) {
        selectedRange = selectionService.rangeByStartDraggingSelection(from: location)
    }

    func updateDragOrigin(to location: Int) {
        selectionService.updateDragOrigin(to: location)
    }

    func extendDraggedSelection(to location: Int) {
        selectedRange = selectionService.rangeByExtendingDraggedSelection(to: location)
    }

    func selectWord(at location: Int) {
        let range = selectionService.rangeBySelectingWord(at: location)
        // Ensure the entire word is laid out before setting selection
        // This is especially important for long words that might wrap
        layoutManager.layoutLines(toLocation: range.upperBound)
        selectedRange = range
    }

    func selectLine(at location: Int) {
        let range = selectionService.rangeBySelectingLine(at: location)
        // Ensure the entire line is laid out before setting selection
        // This fixes an issue where only the visible portion of a wrapped line
        // would be highlighted until scrolling forced layout
        layoutManager.layoutLines(toLocation: range.upperBound)
        selectedRange = range
    }

    func movePageUpAndModifySelection() {
        guard let selectedRange = selectedRange else {
            return
        }

        let pageHeight = calculatePageHeight()
        let currentRect = caretRectInDocument(at: selectedRange.upperBound)
        let targetY = currentRect.minY - pageHeight
        let targetPoint = CGPoint(x: currentRect.minX, y: max(0, targetY))
        let newLocation = characterIndex(at: targetPoint)

        extendSelection(to: newLocation)
        scrollLocationToVisible(newLocation)
    }

    func movePageDownAndModifySelection() {
        guard let selectedRange = selectedRange else {
            return
        }

        let pageHeight = calculatePageHeight()
        let currentRect = caretRectInDocument(at: selectedRange.upperBound)
        let targetY = currentRect.minY + pageHeight
        let targetPoint = CGPoint(x: currentRect.minX, y: targetY)
        let newLocation = characterIndex(at: targetPoint)

        extendSelection(to: newLocation)
        scrollLocationToVisible(newLocation)
    }

    private func extendSelection(to newLocation: Int) {
        guard let currentRange = selectedRange else {
            return
        }

        // Determine anchor point (where selection started)
        let anchor = currentRange.length > 0 ? currentRange.location : currentRange.location

        let newRange: NSRange
        if newLocation >= anchor {
            newRange = NSRange(location: anchor, length: newLocation - anchor)
        } else {
            newRange = NSRange(location: newLocation, length: anchor - newLocation)
        }

        selectedRange = newRange
    }
}

private extension TextViewController {
    private func move(by granularity: TextGranularity, inDirection direction: TextDirection) {
        if let selectedRange {
            let newRange = selectionService.range(moving: selectedRange, by: granularity, inDirection: direction)
            self.selectedRange = newRange
            // Scroll to keep the active selection endpoint visible
            // When extending backward, the lowerBound is moving; when extending forward, the upperBound is moving
            let locationToScroll = direction == .backward ? newRange.lowerBound : newRange.upperBound
            scrollLocationToVisible(locationToScroll)
        }
    }

    private func move(toBoundary boundary: TextBoundary, inDirection direction: TextDirection) {
        if let selectedRange {
            let newRange = selectionService.range(moving: selectedRange, toBoundary: boundary, inDirection: direction)
            self.selectedRange = newRange
            // Scroll to keep the active selection endpoint visible
            let locationToScroll = direction == .backward ? newRange.lowerBound : newRange.upperBound
            scrollLocationToVisible(locationToScroll)
        }
    }
}
#endif
