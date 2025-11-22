#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

struct DefaultStringAttributes {
    let textColor: MultiPlatformColor
    let font: MultiPlatformFont
    let kern: CGFloat
    let tabWidth: CGFloat

    func apply(to attributedString: NSMutableAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = (0 ..< 20).map { index in
            NSTextTab(textAlignment: .natural, location: CGFloat(index) * tabWidth)
        }
        paragraphStyle.defaultTabInterval = tabWidth
        let range = NSRange(location: 0, length: attributedString.length)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            .kern: kern as NSNumber,
            .paragraphStyle: paragraphStyle
        ]
        attributedString.beginEditing()
        attributedString.setAttributes(attributes, range: range)
        attributedString.endEditing()
    }
}
