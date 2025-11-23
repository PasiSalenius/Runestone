import Foundation

/// Category of a highlighted range.
public enum HighlightCategory: Hashable, Sendable {
    /// Highlights created by the search/find functionality.
    case search
    /// Custom application-defined highlight category.
    case custom(String)
}

/// Range of text to highlight.
public final class HighlightedRange {
    /// Unique identifier of the highlighted range.
    public let id: String
    /// Range in the text to highlight.
    public let range: NSRange
    /// Color to highlight the text with.
    public let color: MultiPlatformColor
    /// Optional text color to use for the highlighted text. If nil, the default text color is used.
    public let textColor: MultiPlatformColor?
    /// Corner radius of the highlight.
    public let cornerRadius: CGFloat
    /// Priority for rendering order. Higher priority highlights are drawn on top of lower priority ones when overlapping.
    public let priority: Int

    /// Create a new highlighted range.
    /// - Parameters:
    ///   - id: ID of the range. Defaults to a UUID.
    ///   - range: Range in the text to highlight.
    ///   - color: Color to highlight the text with.
    ///   - textColor: Optional text color for the highlighted text. Defaults to nil (uses default text color).
    ///   - cornerRadius: Corner radius of the highlight. A value of zero or less means no corner radius. Defaults to 0.
    ///   - priority: Priority for rendering order. Higher values are drawn on top. Defaults to 0.
    public init(id: String = UUID().uuidString, range: NSRange, color: MultiPlatformColor, textColor: MultiPlatformColor? = nil, cornerRadius: CGFloat = 0, priority: Int = 0) {
        self.id = id
        self.range = range
        self.color = color
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.priority = priority
    }
}

extension HighlightedRange: Equatable {
    public static func == (lhs: HighlightedRange, rhs: HighlightedRange) -> Bool {
        lhs.id == rhs.id && lhs.range == rhs.range && lhs.color == rhs.color && lhs.textColor == rhs.textColor && lhs.priority == rhs.priority
    }
}

extension HighlightedRange: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[HighightedRange range=\(range)]"
    }
}
