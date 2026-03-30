import Foundation

protocol CommentControllerDelegate: AnyObject {
    func commentController(_ controller: CommentController, shouldInsert text: String, in range: NSRange)
    func commentController(_ controller: CommentController, shouldSelect range: NSRange)
}

final class CommentController {
    weak var delegate: CommentControllerDelegate?
    var stringView: StringView
    var lineManager: LineManager

    private let lineCommentPrefix = "// "
    private let lineCommentMarker = "//"
    private let blockCommentOpen = "/*"
    private let blockCommentClose = "*/"

    init(stringView: StringView, lineManager: LineManager) {
        self.stringView = stringView
        self.lineManager = lineManager
    }

    func toggleComment(in selectedRange: NSRange) {
        let lines = effectiveLines(in: selectedRange)
        guard !lines.isEmpty else {
            return
        }
        if isPartialSingleLineSelection(selectedRange, in: lines) {
            toggleBlockComment(in: selectedRange)
        } else {
            toggleLineComment(in: selectedRange, lines: lines)
        }
    }
}

// MARK: - Line Comments
private extension CommentController {
    func toggleLineComment(in selectedRange: NSRange, lines: [DocumentLineNode]) {
        let originalRange = range(surrounding: lines)
        let lineStrings = lines.map { lineString(for: $0) }
        let indentColumn = minimumIndentColumn(in: lineStrings)
        let shouldUncomment = allNonBlankLinesCommented(lineStrings, at: indentColumn)
        var newSelectedRange = selectedRange
        var replacementString = ""
        for (lineIndex, lineString) in lineStrings.enumerated() {
            let (line, delta): (String, Int)
            if shouldUncomment {
                (line, delta) = removingLineComment(from: lineString, at: indentColumn)
            } else {
                (line, delta) = insertingLineComment(in: lineString, at: indentColumn)
            }
            replacementString += line
            if lineIndex == 0 {
                let adjustment = shouldUncomment ? -delta : delta
                let preferredLocation = newSelectedRange.location + adjustment
                let newLocation = max(preferredLocation, originalRange.location)
                let overflow = newLocation - preferredLocation
                if overflow > 0 {
                    newSelectedRange.length = max(newSelectedRange.length - overflow, 0)
                }
                newSelectedRange.location = newLocation
            } else {
                if shouldUncomment {
                    newSelectedRange.length = max(newSelectedRange.length - delta, 0)
                } else {
                    newSelectedRange.length += delta
                }
            }
        }
        delegate?.commentController(self, shouldInsert: replacementString, in: originalRange)
        delegate?.commentController(self, shouldSelect: newSelectedRange)
    }

    func allNonBlankLinesCommented(_ lineStrings: [String], at indentColumn: Int) -> Bool {
        lineStrings.allSatisfy { lineString in
            let content = contentPortion(of: lineString)
            return isBlank(content) || content.dropFirst(indentColumn).hasPrefix(lineCommentMarker)
        }
    }

    func minimumIndentColumn(in lineStrings: [String]) -> Int {
        var minIndent = Int.max
        for lineString in lineStrings {
            let content = contentPortion(of: lineString)
            guard !isBlank(content) else {
                continue
            }
            let whitespaceCount = content.prefix(while: { $0 == " " || $0 == "\t" }).count
            minIndent = min(minIndent, whitespaceCount)
        }
        return minIndent == Int.max ? 0 : minIndent
    }

    func insertingLineComment(in lineString: String, at indentColumn: Int) -> (line: String, addedUTF16Length: Int) {
        let content = contentPortion(of: lineString)
        let delimiter = delimiterPortion(of: lineString)
        guard !isBlank(content) else {
            return (lineString, 0)
        }
        let insertIndex = content.index(content.startIndex, offsetBy: indentColumn)
        let commented = content[..<insertIndex] + lineCommentPrefix + content[insertIndex...] + delimiter
        return (String(commented), lineCommentPrefix.utf16.count)
    }

    func removingLineComment(from lineString: String, at indentColumn: Int) -> (line: String, removedUTF16Length: Int) {
        let content = contentPortion(of: lineString)
        let delimiter = delimiterPortion(of: lineString)
        guard !isBlank(content) else {
            return (lineString, 0)
        }
        let indentEnd = content.index(content.startIndex, offsetBy: indentColumn)
        let afterIndent = content[indentEnd...]
        let prefixToRemove: String
        if afterIndent.hasPrefix(lineCommentPrefix) {
            prefixToRemove = lineCommentPrefix
        } else if afterIndent.hasPrefix(lineCommentMarker) {
            prefixToRemove = lineCommentMarker
        } else {
            return (lineString, 0)
        }
        let uncommented = content[..<indentEnd] + afterIndent.dropFirst(prefixToRemove.count) + delimiter
        return (String(uncommented), prefixToRemove.utf16.count)
    }
}

// MARK: - Block Comments
private extension CommentController {
    func toggleBlockComment(in selectedRange: NSRange) {
        guard let selectedText = stringView.substring(in: selectedRange) else {
            return
        }
        let isCommented = selectedText.hasPrefix(blockCommentOpen) && selectedText.hasSuffix(blockCommentClose)
        let replacementText: String
        if isCommented {
            replacementText = String(selectedText.dropFirst(blockCommentOpen.count).dropLast(blockCommentClose.count))
        } else {
            replacementText = blockCommentOpen + selectedText + blockCommentClose
        }
        delegate?.commentController(self, shouldInsert: replacementText, in: selectedRange)
        delegate?.commentController(self, shouldSelect: NSRange(location: selectedRange.location, length: replacementText.utf16.count))
    }
}

// MARK: - Helpers
private extension CommentController {
    func effectiveLines(in selectedRange: NSRange) -> [DocumentLineNode] {
        var lines = lineManager.lines(in: selectedRange)
        // When shift-selecting whole lines, the cursor lands at the beginning of the next line.
        // That line is not visually highlighted and should be excluded, matching Xcode behavior.
        if lines.count > 1, selectedRange.length > 0, let lastLine = lines.last,
           selectedRange.location + selectedRange.length == lastLine.location {
            lines.removeLast()
        }
        return lines
    }

    func isPartialSingleLineSelection(_ selectedRange: NSRange, in lines: [DocumentLineNode]) -> Bool {
        guard lines.count == 1, selectedRange.length > 0 else {
            return false
        }
        let line = lines[0]
        let startsAtLineStart = selectedRange.location == line.location
        let endsAtLineEnd = selectedRange.location + selectedRange.length >= line.location + line.data.length
        return !startsAtLineStart || !endsAtLineEnd
    }

    func lineString(for line: DocumentLineNode) -> String {
        let lineRange = NSRange(location: line.location, length: line.data.totalLength)
        return stringView.substring(in: lineRange) ?? ""
    }

    /// Returns the content portion of a line string, excluding the trailing newline characters.
    func contentPortion(of lineString: String) -> Substring {
        var endIndex = lineString.endIndex
        while endIndex > lineString.startIndex {
            let prevIndex = lineString.index(before: endIndex)
            if lineString[prevIndex] == "\n" || lineString[prevIndex] == "\r" {
                endIndex = prevIndex
            } else {
                break
            }
        }
        return lineString[..<endIndex]
    }

    /// Returns the trailing newline characters of a line string.
    func delimiterPortion(of lineString: String) -> Substring {
        let content = contentPortion(of: lineString)
        return lineString[content.endIndex...]
    }

    func isBlank(_ content: Substring) -> Bool {
        content.isEmpty || content.allSatisfy { $0 == " " || $0 == "\t" }
    }

    func range(surrounding lines: [DocumentLineNode]) -> NSRange {
        let firstLine = lines[0]
        let lastLine = lines[lines.count - 1]
        let location = firstLine.location
        let length = (lastLine.location - location) + lastLine.data.totalLength
        return NSRange(location: location, length: length)
    }
}
