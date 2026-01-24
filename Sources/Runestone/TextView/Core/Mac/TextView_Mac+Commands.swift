#if os(macOS)
import AppKit

public extension TextView {
    /// Deletes a character from the displayed text.
    override func deleteForward(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length == 0 else {
            deleteBackward(nil)
            return
        }
        guard selectedRange.location < textViewController.stringView.string.length else {
            return
        }
        textViewController.selectedRange = NSRange(location: selectedRange.location, length: 1)
        deleteBackward(nil)
    }

    /// Deletes a character from the displayed text.
    override func deleteBackward(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard var selectedRange = textViewController.markedRange ?? textViewController.selectedRange?.nonNegativeLength else {
            return
        }
        guard selectedRange.location > 0 || selectedRange.length > 0 else {
            return
        }
        if selectedRange.length == 0 {
            selectedRange.location -= 1
            selectedRange.length = 1
        }
        let deleteRange = textViewController.rangeForDeletingText(in: selectedRange)
        // If we're deleting everything in the marked range then we clear the marked range. UITextInput doesn't do that for us.
        // Can be tested by entering a backtick (`) in an empty document and deleting it.
        if deleteRange == textViewController.markedRange {
            textViewController.markedRange = nil
        }
        guard textViewController.shouldChangeText(in: deleteRange, replacementText: "") else {
            return
        }
        let isDeletingMultipleCharacters = selectedRange.length > 1
        if isDeletingMultipleCharacters {
            undoManager?.endUndoGrouping()
            undoManager?.beginUndoGrouping()
        }
        textViewController.replaceText(in: deleteRange, with: "", selectedRangeAfterUndo: selectedRange)
        if isDeletingMultipleCharacters {
            undoManager?.endUndoGrouping()
        }
    }

    /// Inserts a newline character.
    override func insertNewline(_ sender: Any?) {
        guard isEditable else {
            return
        }
        if textViewController.shouldChangeText(in: textViewController.rangeForInsertingText, replacementText: lineEndings.symbol) {
            textViewController.indentController.insertLineBreak(in: textViewController.rangeForInsertingText, using: lineEndings.symbol)
        }
    }

    /// Inserts a tab character.
    override func insertTab(_ sender: Any?) {
        guard isEditable else {
            return
        }
        let indentString = indentStrategy.string(indentLevel: 1)
        if textViewController.shouldChangeText(in: textViewController.rangeForInsertingText, replacementText: indentString) {
            textViewController.replaceText(in: textViewController.rangeForInsertingText, with: indentString)
        }
    }

    /// Copy the selected text.
    ///
    /// - Parameter sender: The object calling this method.
    @objc func copy(_ sender: Any?) {
        let selectedRange = selectedRange()
        if selectedRange.length > 0, let text = textViewController.text(in: selectedRange) {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    /// Paste text from the pasteboard.
    ///
    /// - Parameter sender: The object calling this method.
    @objc func paste(_ sender: Any?) {
        guard isEditable else {
            return
        }
        let selectedRange = selectedRange()
        if let string = NSPasteboard.general.string(forType: .string) {
            let preparedText = textViewController.prepareTextForInsertion(string)
            textViewController.replaceText(in: selectedRange, with: preparedText)
        }
    }

    /// Cut text  to the pasteboard.
    ///
    /// - Parameter sender: The object calling this method.
    @objc func cut(_ sender: Any?) {
        guard isEditable else {
            return
        }
        let selectedRange = selectedRange()
        if selectedRange.length > 0, let text = textViewController.text(in: selectedRange) {
            NSPasteboard.general.setString(text, forType: .string)
            textViewController.replaceText(in: selectedRange, with: "")
        }
    }

    /// Select all text in the text view.
    ///
    /// - Parameter sender: The object calling this method.
    override func selectAll(_ sender: Any?) {
        textViewController.selectedRange = NSRange(location: 0, length: textViewController.stringView.string.length)
    }

    /// Performs the undo operations in the last undo group.
    @objc func undo(_ sender: Any?) {
        guard isEditable else {
            return
        }
        if let undoManager = undoManager, undoManager.canUndo {
            undoManager.undo()
        }
    }

    /// Performs the operations in the last group on the redo stack.
    @objc func redo(_ sender: Any?) {
        guard isEditable else {
            return
        }
        if let undoManager = undoManager, undoManager.canRedo {
            undoManager.redo()
        }
    }

    /// Delete the word in front of the insertion point.
    override func deleteWordForward(_ sender: Any?) {
        guard isEditable else {
            return
        }
        deleteText(toBoundary: .word, inDirection: .forward)
    }

    /// Delete the word behind the insertion point.
    override func deleteWordBackward(_ sender: Any?) {
        guard isEditable else {
            return
        }
        deleteText(toBoundary: .word, inDirection: .backward)
    }

    // MARK: - Emacs-Style Keyboard Shortcuts

    /// Control+A - Move to beginning of line (Emacs-style)
    override func moveToLeftEndOfLine(_ sender: Any?) {
        textViewController.moveToBeginningOfLine()
    }

    /// Control+E - Move to end of line (Emacs-style)
    override func moveToRightEndOfLine(_ sender: Any?) {
        textViewController.moveToEndOfLine()
    }

    /// Control+K - Delete to end of line (kill line)
    /// Note: macOS maps Control+K to deleteToEndOfParagraph, not deleteToEndOfLine
    override func deleteToEndOfParagraph(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length == 0 else {
            // If there's a selection, just delete it
            deleteBackward(nil)
            return
        }

        let lineManager = textViewController.lineManager

        // Find the end of the current line
        guard let line = lineManager.line(containingCharacterAt: selectedRange.location) else {
            return
        }

        let lineEndLocation = line.location + line.data.length
        let deletionRange: NSRange

        // If we're at the end of the line, delete the line ending character
        if selectedRange.location == lineEndLocation {
            // Delete newline character
            deletionRange = NSRange(location: selectedRange.location, length: line.data.delimiterLength)
        } else {
            // Delete from cursor to end of line (not including newline)
            deletionRange = NSRange(
                location: selectedRange.location,
                length: lineEndLocation - selectedRange.location
            )
        }

        guard deletionRange.length > 0 else {
            return
        }

        // Select the range to delete, then call deleteBackward to handle it
        textViewController.selectedRange = deletionRange
        deleteBackward(nil)
    }

    /// Command+Delete - Delete to beginning of line
    override func deleteToBeginningOfLine(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length == 0 else {
            // If there's a selection, just delete it
            deleteBackward(nil)
            return
        }

        let lineManager = textViewController.lineManager

        // Find the beginning of the current line
        guard let line = lineManager.line(containingCharacterAt: selectedRange.location) else {
            return
        }

        let deletionRange = NSRange(
            location: line.location,
            length: selectedRange.location - line.location
        )

        guard deletionRange.length > 0 else {
            return
        }

        // Select the range to delete, then call deleteBackward to handle it
        textViewController.selectedRange = deletionRange
        deleteBackward(nil)
    }

    /// Control+T - Transpose characters (swap before/after cursor)
    override func transpose(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length == 0 else {
            // Don't transpose if there's a selection
            return
        }

        let string = textViewController.stringView.string
        let location = selectedRange.location

        // Need at least one character before and after, or at end of non-empty string
        guard location > 0 && location <= string.length else {
            return
        }

        let beforeLocation: Int
        let afterLocation: Int

        if location == string.length && location >= 2 {
            // At end of string: swap last two characters
            beforeLocation = location - 2
            afterLocation = location - 1
        } else if location > 0 && location < string.length {
            // In middle: swap character before and after cursor
            beforeLocation = location - 1
            afterLocation = location
        } else {
            return
        }

        let beforeRange = NSRange(location: beforeLocation, length: 1)
        let afterRange = NSRange(location: afterLocation, length: 1)

        guard let beforeChar = textViewController.text(in: beforeRange),
              let afterChar = textViewController.text(in: afterRange) else {
            return
        }

        // Perform the swap
        let combinedRange = NSRange(location: beforeLocation, length: 2)
        let swappedText = afterChar + beforeChar

        textViewController.replaceText(in: combinedRange, with: swappedText)
        // Move cursor past the swapped characters
        textViewController.selectedRange = NSRange(location: afterLocation + 1, length: 0)
    }

    /// Control+O - Insert newline without moving cursor
    override func insertNewlineIgnoringFieldEditor(_ sender: Any?) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }

        let newlineSymbol = lineEndings.symbol
        guard textViewController.shouldChangeText(in: selectedRange, replacementText: newlineSymbol) else {
            return
        }

        let originalLocation = selectedRange.location
        textViewController.replaceText(in: selectedRange, with: newlineSymbol)

        // Restore cursor position asynchronously to ensure all text processing completes first
        DispatchQueue.main.async { [weak self] in
            self?.textViewController.selectedRange = NSRange(location: originalLocation, length: 0)
        }
    }

    // MARK: - Text Transformations

    /// Transform selected text to uppercase
    override func uppercaseWord(_ sender: Any?) {
        transformSelectedText { $0.uppercased() }
    }

    /// Transform selected text to lowercase
    override func lowercaseWord(_ sender: Any?) {
        transformSelectedText { $0.lowercased() }
    }

    /// Capitalize first letter of each word in selection
    override func capitalizeWord(_ sender: Any?) {
        transformSelectedText { $0.capitalized }
    }

    private func transformSelectedText(using transformation: (String) -> String) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length > 0 else {
            // No selection, nothing to transform
            return
        }
        guard let selectedText = textViewController.text(in: selectedRange) else {
            return
        }

        let transformedText = transformation(selectedText)

        // Only replace if text actually changed
        guard transformedText != selectedText else {
            return
        }

        // Perform replacement
        textViewController.replaceText(in: selectedRange, with: transformedText)

        // Restore selection to transformed text
        textViewController.selectedRange = NSRange(
            location: selectedRange.location,
            length: transformedText.count
        )
    }
}

private extension TextView {
    private func deleteText(toBoundary boundary: TextBoundary, inDirection direction: TextDirection) {
        guard isEditable else {
            return
        }
        guard let selectedRange = textViewController.selectedRange else {
            return
        }
        guard selectedRange.length == 0 else {
            deleteBackward(nil)
            return
        }
        guard let range = rangeForDeleting(from: selectedRange.location, toBoundary: boundary, inDirection: direction) else {
            return
        }
        textViewController.selectedRange = range
        deleteBackward(nil)
    }

    private func rangeForDeleting(from sourceLocation: Int, toBoundary boundary: TextBoundary, inDirection direction: TextDirection) -> NSRange? {
        let stringTokenizer = StringTokenizer(
            stringView: textViewController.stringView,
            lineManager: textViewController.lineManager,
            lineControllerStorage: textViewController.lineControllerStorage
        )
        guard let destinationLocation = stringTokenizer.location(from: sourceLocation, toBoundary: boundary, inDirection: direction) else {
            return nil
        }
        let lowerBound = min(sourceLocation, destinationLocation)
        let upperBound = max(sourceLocation, destinationLocation)
        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }
}
#endif
