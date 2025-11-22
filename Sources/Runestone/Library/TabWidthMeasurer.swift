#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

enum TabWidthMeasurer {
    static func tabWidth(tabLength: Int, font: MultiPlatformFont) -> CGFloat {
        let str = String(repeating: " ", count: tabLength)
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        #if os(macOS)
        let options: NSString.DrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        #endif
        #if os(iOS)
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        #endif
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let bounds = str.boundingRect(with: maxSize, options: options, attributes: attributes, context: nil)
        return round(bounds.size.width)
    }
}
