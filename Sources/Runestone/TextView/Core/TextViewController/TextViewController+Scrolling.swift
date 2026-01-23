import Foundation

 extension TextViewController {
    func scrollRangeToVisible(_ range: NSRange, applyScrollPadding: Bool = true) {
        layoutManager.layoutLines(toLocation: range.upperBound)
        justScrollRangeToVisible(range, applyScrollPadding: applyScrollPadding)
    }

    func scrollLocationToVisible(_ location: Int, applyScrollPadding: Bool = true) {
        let range = NSRange(location: location, length: 0)
        justScrollRangeToVisible(range, applyScrollPadding: applyScrollPadding)
    }
}

private extension TextViewController {
    private func justScrollRangeToVisible(_ range: NSRange, applyScrollPadding: Bool) {
        let lowerBoundRect = caretRect(at: range.lowerBound)
        let upperBoundRect = range.length == 0 ? lowerBoundRect : caretRect(at: range.upperBound)
        let rectMinX = min(lowerBoundRect.minX, upperBoundRect.minX)
        let rectMaxX = max(lowerBoundRect.maxX, upperBoundRect.maxX)
        let rectMinY = min(lowerBoundRect.minY, upperBoundRect.minY)
        let rectMaxY = max(lowerBoundRect.maxY, upperBoundRect.maxY)
        let rect = CGRect(x: rectMinX, y: rectMinY, width: rectMaxX - rectMinX, height: rectMaxY - rectMinY)
        scrollView.contentOffset = contentOffsetForScrollingToVisibleRect(rect, applyScrollPadding: applyScrollPadding)
    }

    private func caretRect(at location: Int) -> CGRect {
        let caretRectFactory = CaretRectFactory(
            stringView: stringView,
            lineManager: lineManager,
            lineControllerStorage: lineControllerStorage,
            gutterWidthService: gutterWidthService,
            textContainerInset: textContainerInset
        )
        return caretRectFactory.caretRect(at: location, allowMovingCaretToNextLineFragment: true)
    }

    /// Computes a content offset to scroll to in order to reveal the specified rectangle.
    ///
    /// The function will return a rectangle that scrolls the text view a minimum amount while revealing as much as possible of the rectangle. It is not guaranteed that the entire rectangle can be revealed.
    /// - Parameter rect: The rectangle to reveal.
    /// - Returns: The content offset to scroll to.
    private func contentOffsetForScrollingToVisibleRect(_ rect: CGRect, applyScrollPadding: Bool) -> CGPoint {
        let scrollPadding: CGFloat = applyScrollPadding ? 60 : 0
        // Create the viewport: a rectangle containing the content that is visible to the user.
        var viewport = CGRect(origin: scrollView.contentOffset, size: textView.frame.size)
        viewport.origin.y += scrollView.adjustedContentInset.top + textContainerInset.top
        viewport.origin.x += scrollView.adjustedContentInset.left + gutterWidth + textContainerInset.left
        viewport.size.width -= scrollView.adjustedContentInset.left
        + scrollView.adjustedContentInset.right
        + gutterWidth
        + textContainerInset.left
        + textContainerInset.right
        viewport.size.height -= scrollView.adjustedContentInset.top
        + scrollView.adjustedContentInset.bottom
        + textContainerInset.top
        + textContainerInset.bottom
        // Construct the best possible content offset.
        var newContentOffset = scrollView.contentOffset
        if rect.minX < viewport.minX + scrollPadding {
            newContentOffset.x -= viewport.minX - rect.minX + scrollPadding
        } else if rect.maxX > viewport.maxX - scrollPadding && rect.width <= viewport.width {
            // The end of the rectangle is not visible and the rect fits within the screen so we'll scroll to reveal the entire rect.
            newContentOffset.x += rect.maxX - viewport.maxX + scrollPadding
        } else if rect.maxX > viewport.maxX {
            newContentOffset.x += rect.minX
        }
        if rect.minY < viewport.minY + scrollPadding {
            newContentOffset.y -= viewport.minY - rect.minY + scrollPadding
        } else if rect.maxY > viewport.maxY - scrollPadding && rect.height <= viewport.height {
            // The end of the rectangle is not visible and the rect fits within the screen so we'll scroll to reveal the entire rect.
            newContentOffset.y += rect.maxY - viewport.maxY + scrollPadding
        } else if rect.maxY > viewport.maxY - scrollPadding {
            // Bottom of rect extends beyond viewport - scroll down just enough to reveal it
            newContentOffset.y += rect.maxY - viewport.maxY + scrollPadding
        }
        let cappedXOffset = min(max(newContentOffset.x, scrollView.minimumContentOffset.x), scrollView.maximumContentOffset.x)
        let cappedYOffset = min(max(newContentOffset.y, scrollView.minimumContentOffset.y), scrollView.maximumContentOffset.y)
        return CGPoint(x: cappedXOffset, y: cappedYOffset)
    }
}
