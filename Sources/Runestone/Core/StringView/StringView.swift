import _RunestoneStringUtilities
import _RunestoneTreeSitter
import Foundation

protocol StringView: AnyObject, TreeSitterStringView {
    var string: NSString { get set }
    var attributedString: NSAttributedString { get }
    func substring(in range: NSRange) -> String?
    func attributedSubstring(in range: NSRange) -> NSAttributedString?
    func replaceText(in range: NSRange, with string: String)
    func bytes(in range: ByteRange) -> BytesView?
}

extension StringView {
    var length: Int {
        attributedString.length
    }

    func substring(in range: NSRange) -> String? {
        attributedSubstring(in: range)?.string
    }

    func bytes(in range: ByteRange) -> BytesView? {
        guard range.lowerBound.value >= 0 && range.upperBound <= attributedString.string.byteCount else {
            return nil
        }
        var usedLength = 0
        guard let buffer = attributedString.string.getBytes(
            in: NSRange(range),
            encoding: String.preferredUTF16Encoding,
            usedLength: &usedLength
        ) else {
            return nil
        }
        return BytesView(bytes: buffer, length: ByteCount(usedLength))
    }
}