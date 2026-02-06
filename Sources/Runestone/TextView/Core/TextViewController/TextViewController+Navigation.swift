import Foundation

extension TextViewController {
    func moveLeft() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .character, inDirection: .backward)
    }

    func moveRight() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .character, inDirection: .forward)
    }

    func moveUp() {
        move(by: .line, inDirection: .backward)
    }

    func moveDown() {
        move(by: .line, inDirection: .forward)
    }

    func moveWordLeft() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .word, inDirection: .backward)
    }

    func moveWordRight() {
        navigationService.resetPreviousLineNavigationOperation()
        move(by: .word, inDirection: .forward)
    }

    func moveToBeginningOfLine() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .line, inDirection: .backward)
    }

    func moveToEndOfLine() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .line, inDirection: .forward)
    }

    func moveToBeginningOfParagraph() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .paragraph, inDirection: .backward)
    }

    func moveToEndOfParagraph() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .paragraph, inDirection: .forward)
    }

    func moveToBeginningOfDocument() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .document, inDirection: .backward)
    }

    func moveToEndOfDocument() {
        navigationService.resetPreviousLineNavigationOperation()
        move(toBoundary: .document, inDirection: .forward)
    }

    func move(to location: Int) {
        navigationService.resetPreviousLineNavigationOperation()
        selectedRange = NSRange(location: location, length: 0)
    }

    func scrollLineUp() {
        let offset = scrollView.contentOffset
        let newY = max(offset.y - estimatedLineHeight, scrollView.minimumContentOffset.y)
        scrollView.contentOffset = CGPoint(x: offset.x, y: newY)
    }

    func scrollLineDown() {
        let offset = scrollView.contentOffset
        let newY = min(offset.y + estimatedLineHeight, scrollView.maximumContentOffset.y)
        scrollView.contentOffset = CGPoint(x: offset.x, y: newY)
    }

    func movePageUp() {
        guard let selectedRange = selectedRange else {
            return
        }

        // Calculate page height in document coordinates
        let pageHeight = self.calculatePageHeight()

        // Find current cursor position
        let currentRect = self.caretRectInDocument(at: selectedRange.location)

        // Calculate target Y position (one page up)
        let targetY = currentRect.minY - pageHeight

        // Find the character at target position
        let targetPoint = CGPoint(x: currentRect.minX, y: max(0, targetY))
        let newLocation = self.characterIndex(at: targetPoint)

        self.selectedRange = NSRange(location: newLocation, length: 0)
        scrollLocationToVisible(newLocation)
    }

    func movePageDown() {
        guard let selectedRange = selectedRange else {
            return
        }

        // Calculate page height
        let pageHeight = self.calculatePageHeight()

        // Find current cursor position
        let currentRect = self.caretRectInDocument(at: selectedRange.location)

        // Calculate target Y position (one page down)
        let targetY = currentRect.minY + pageHeight

        // Find the character at target position
        let targetPoint = CGPoint(x: currentRect.minX, y: targetY)
        let newLocation = self.characterIndex(at: targetPoint)

        self.selectedRange = NSRange(location: newLocation, length: 0)
        scrollLocationToVisible(newLocation)
    }

    // MARK: - Page Navigation Helpers

    func calculatePageHeight() -> CGFloat {
        // Calculate the visible height of the text area
        let viewportHeight = textView.frame.size.height
        let pageHeight = viewportHeight
            - scrollView.adjustedContentInset.top
            - scrollView.adjustedContentInset.bottom
            - textContainerInset.top
            - textContainerInset.bottom
        return max(0, pageHeight)
    }

    func caretRectInDocument(at location: Int) -> CGRect {
        let caretRectFactory = CaretRectFactory(
            stringView: stringView,
            lineManager: lineManager,
            lineControllerStorage: lineControllerStorage,
            gutterWidthService: gutterWidthService,
            textContainerInset: textContainerInset
        )
        return caretRectFactory.caretRect(at: location, allowMovingCaretToNextLineFragment: true)
    }

    func characterIndex(at point: CGPoint) -> Int {
        // Adjust point to text coordinate system (excluding gutter and insets)
        let adjustedPoint = CGPoint(
            x: point.x - gutterWidth - textContainerInset.left,
            y: point.y - textContainerInset.top
        )

        // Use layout manager to find the closest character index
        let index = layoutManager.closestIndex(to: adjustedPoint)
        return max(0, min(index, stringView.string.length))
    }
}

private extension TextViewController {
    private func move(by granularity: TextGranularity, inDirection direction: TextDirection) {
        guard let selectedRange = selectedRange?.nonNegativeLength else {
            return
        }
        let newLocation: Int
        switch granularity {
        case .character:
            if selectedRange.length == 0 {
                let sourceLocation = selectedRange.bound(in: direction)
                newLocation = navigationService.location(movingFrom: sourceLocation, byCharacterCount: 1, inDirection: direction)
            } else {
                newLocation = selectedRange.bound(in: direction)
            }
        case .line:
            let sourceLocation = selectedRange.bound(in: direction)
            newLocation = navigationService.location(movingFrom: sourceLocation, byLineCount: 1, inDirection: direction)
        case .word:
            let sourceLocation = selectedRange.bound(in: direction)
            newLocation = navigationService.location(movingFrom: sourceLocation, byWordCount: 1, inDirection: direction)
        }
        self.selectedRange = NSRange(location: newLocation, length: 0)
        scrollLocationToVisible(newLocation)
    }

    private func move(toBoundary boundary: TextBoundary, inDirection direction: TextDirection) {
        guard let selectedRange = selectedRange?.nonNegativeLength else {
            return
        }
        let sourceLocation = selectedRange.bound(in: direction)
        let location = navigationService.location(moving: sourceLocation, toBoundary: boundary, inDirection: direction)
        self.selectedRange = NSRange(location: location, length: 0)
        scrollLocationToVisible(location)
    }
}

private extension NSRange {
    func bound(in direction: TextDirection) -> Int {
        switch direction {
        case .backward:
            return lowerBound
        case .forward:
            return upperBound
        }
    }
}
