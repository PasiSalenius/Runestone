import Foundation

protocol CommentControllerDelegate: AnyObject {
    func commentController(_ controller: CommentController, shouldInsert text: String, in range: NSRange)
    func commentController(_ controller: CommentController, shouldSelect range: NSRange)
}

final class CommentController {
    weak var delegate: CommentControllerDelegate?
    var stringView: StringView
    var lineManager: LineManager

    private let commentPrefix = "// "
    private let commentPrefixNoSpace = "//"
    private let blockCommentOpen = "/*"
    private let blockCommentClose = "*/"

    init(stringView: StringView, lineManager: LineManager) {
        self.stringView = stringView
        self.lineManager = lineManager
    }

    func toggleComment(in selectedRange: NSRange) {
        var lines = lineManager.lines(in: selectedRange)
        guard !lines.isEmpty else {
            return
        }
        // If the selection ends exactly at the start of the last line, exclude that line.
        // This happens when shift-selecting whole lines: the cursor lands at the beginning
        // of the next line, but visually that line is not highlighted and Xcode excludes it.
        if lines.count > 1, selectedRange.length > 0, let lastLine = lines.last,
           selectedRange.location + selectedRange.length == lastLine.location {
            lines.removeLast()
        }
        // Partial selection within a single line → use block comments.
        if lines.count == 1, selectedRange.length > 0 {
            let line = lines[0]
            let selectionStartsAtLineStart = selectedRange.location == line.location
            let selectionEndsAtLineEnd = selectedRange.location + selectedRange.length >= line.location + line.data.length
            if !selectionStartsAtLineStart || !selectionEndsAtLineEnd {
                toggleBlockComment(in: selectedRange)
                return
            }
        }
        let originalRange = range(surrounding: lines)
        // Get line strings (including their delimiters).
        let lineStrings: [String] = lines.map { line in
            let lineRange = NSRange(location: line.location, length: line.data.totalLength)
            return stringView.substring(in: lineRange) ?? ""
        }
        // Determine whether to comment or uncomment.
        // Uncomment if ALL non-blank lines are already commented.
        let shouldUncomment = lineStrings.allSatisfy { lineString in
            let content = contentAfterDelimiter(in: lineString)
            return isBlankContent(content) || content.hasPrefix(commentPrefixNoSpace)
        }
        var newSelectedRange = selectedRange
        var replacementString = ""
        for (lineIndex, lineString) in lineStrings.enumerated() {
            if shouldUncomment {
                let result = uncommentedLine(lineString)
                replacementString += result.line
                let delta = result.removedUTF16Length
                if lineIndex == 0 {
                    let preferredLocation = newSelectedRange.location - delta
                    let newLocation = max(preferredLocation, originalRange.location)
                    if newLocation > preferredLocation {
                        let preferredLength = newSelectedRange.length - (newLocation - preferredLocation)
                        newSelectedRange.length = max(preferredLength, 0)
                    }
                    newSelectedRange.location = newLocation
                } else {
                    newSelectedRange.length = max(newSelectedRange.length - delta, 0)
                }
            } else {
                let result = commentedLine(lineString)
                replacementString += result.line
                let delta = result.addedUTF16Length
                if lineIndex == 0 {
                    newSelectedRange.location += delta
                } else {
                    newSelectedRange.length += delta
                }
            }
        }
        delegate?.commentController(self, shouldInsert: replacementString, in: originalRange)
        delegate?.commentController(self, shouldSelect: newSelectedRange)
    }
}

private extension CommentController {
    func toggleBlockComment(in selectedRange: NSRange) {
        guard let selectedText = stringView.substring(in: selectedRange) else {
            return
        }
        if selectedText.hasPrefix(blockCommentOpen) && selectedText.hasSuffix(blockCommentClose) {
            // Uncomment: remove /* and */
            let openLen = blockCommentOpen.count
            let closeLen = blockCommentClose.count
            let startIndex = selectedText.index(selectedText.startIndex, offsetBy: openLen)
            let endIndex = selectedText.index(selectedText.endIndex, offsetBy: -closeLen)
            let uncommented = String(selectedText[startIndex..<endIndex])
            delegate?.commentController(self, shouldInsert: uncommented, in: selectedRange)
            let newLength = uncommented.utf16.count
            delegate?.commentController(self, shouldSelect: NSRange(location: selectedRange.location, length: newLength))
        } else {
            // Comment: wrap with /* */
            let commented = blockCommentOpen + selectedText + blockCommentClose
            delegate?.commentController(self, shouldInsert: commented, in: selectedRange)
            let newLength = commented.utf16.count
            delegate?.commentController(self, shouldSelect: NSRange(location: selectedRange.location, length: newLength))
        }
    }

    /// Returns the line content portion (excluding the trailing line delimiter) from a full line string.
    func contentAfterDelimiter(in lineString: String) -> String {
        // Line strings from the line manager include trailing newline characters.
        // We need to strip those to check the actual content.
        var content = lineString
        while content.hasSuffix("\n") || content.hasSuffix("\r") {
            content = String(content.dropLast())
        }
        // Strip leading whitespace to check the prefix.
        let trimmed = content.drop(while: { $0 == " " || $0 == "\t" })
        return String(trimmed)
    }

    func isBlankContent(_ content: String) -> Bool {
        content.allSatisfy { $0 == " " || $0 == "\t" || $0.isNewline } || content.isEmpty
    }

    /// Adds `// ` after leading whitespace. Returns the modified line and the number of UTF-16 units added.
    /// Blank lines (content-wise) are returned unchanged with delta 0.
    func commentedLine(_ lineString: String) -> (line: String, addedUTF16Length: Int) {
        // Find the boundary between line content and delimiter.
        let (content, delimiter) = splitLineAndDelimiter(lineString)
        guard !isBlankContent(String(content)) else {
            return (lineString, 0)
        }
        // Find end of leading whitespace.
        let leadingWhitespace = content.prefix(while: { $0 == " " || $0 == "\t" })
        let rest = content[leadingWhitespace.endIndex...]
        let commented = leadingWhitespace + commentPrefix + rest + delimiter
        return (String(commented), commentPrefix.utf16.count)
    }

    /// Removes `// ` or `//` after leading whitespace. Returns the modified line and the number of UTF-16 units removed.
    func uncommentedLine(_ lineString: String) -> (line: String, removedUTF16Length: Int) {
        let (content, delimiter) = splitLineAndDelimiter(lineString)
        let trimmedContent = contentAfterDelimiter(in: lineString)
        guard trimmedContent.hasPrefix(commentPrefixNoSpace) else {
            return (lineString, 0)
        }
        let leadingWhitespace = content.prefix(while: { $0 == " " || $0 == "\t" })
        let afterWhitespace = content[leadingWhitespace.endIndex...]
        let removedLength: Int
        let remaining: Substring
        if afterWhitespace.hasPrefix(commentPrefix) {
            remaining = afterWhitespace[afterWhitespace.index(afterWhitespace.startIndex, offsetBy: commentPrefix.count)...]
            removedLength = commentPrefix.utf16.count
        } else {
            remaining = afterWhitespace[afterWhitespace.index(afterWhitespace.startIndex, offsetBy: commentPrefixNoSpace.count)...]
            removedLength = commentPrefixNoSpace.utf16.count
        }
        let uncommented = leadingWhitespace + remaining + delimiter
        return (String(uncommented), removedLength)
    }

    /// Splits a line string into its content and trailing delimiter (newline characters).
    func splitLineAndDelimiter(_ lineString: String) -> (content: Substring, delimiter: Substring) {
        var endIndex = lineString.endIndex
        while endIndex > lineString.startIndex {
            let prevIndex = lineString.index(before: endIndex)
            let char = lineString[prevIndex]
            if char == "\n" || char == "\r" {
                endIndex = prevIndex
            } else {
                break
            }
        }
        return (lineString[lineString.startIndex..<endIndex], lineString[endIndex..<lineString.endIndex])
    }

    func range(surrounding lines: [DocumentLineNode]) -> NSRange {
        let firstLine = lines[0]
        let lastLine = lines[lines.count - 1]
        let location = firstLine.location
        let length = (lastLine.location - location) + lastLine.data.totalLength
        return NSRange(location: location, length: length)
    }
}
