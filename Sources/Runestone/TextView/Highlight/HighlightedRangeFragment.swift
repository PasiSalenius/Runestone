import Foundation

final class HighlightedRangeFragment: Equatable {
    let range: NSRange
    let containsStart: Bool
    let containsEnd: Bool
    let color: MultiPlatformColor
    let textColor: MultiPlatformColor?
    let cornerRadius: CGFloat

    init(range: NSRange, containsStart: Bool, containsEnd: Bool, color: MultiPlatformColor, textColor: MultiPlatformColor? = nil, cornerRadius: CGFloat) {
        self.range = range
        self.containsStart = containsStart
        self.containsEnd = containsEnd
        self.color = color
        self.textColor = textColor
        self.cornerRadius = cornerRadius
    }
}

extension HighlightedRangeFragment {
    static func == (lhs: HighlightedRangeFragment, rhs: HighlightedRangeFragment) -> Bool {
        lhs.range == rhs.range
        && lhs.containsStart == rhs.containsStart
        && lhs.containsEnd == rhs.containsEnd
        && lhs.color == rhs.color
        && lhs.textColor == rhs.textColor
        && lhs.cornerRadius == rhs.cornerRadius
    }
}
