#if os(macOS)
import AppKit
#endif
import Combine
import CoreText
import Foundation
#if os(iOS)
import UIKit
#endif

protocol LineFragmentRendererDelegate: AnyObject {
    func string(in lineFragmentRenderer: LineFragmentRenderer) -> String?
}

final class LineFragmentRenderer {
    private enum HorizontalPosition {
        case character(Int)
        case endOfLine
    }

    weak var delegate: LineFragmentRendererDelegate?
    var lineFragment: LineFragment
    var markedRange: NSRange?
    var highlightedRangeFragments: [HighlightedRangeFragment] = []

    private let invisibleCharacterSettings: InvisibleCharacterSettings
    private let markedTextBackgroundColor: CurrentValueSubject<MultiPlatformColor, Never>
    private let markedTextBackgroundCornerRadius: CurrentValueSubject<CGFloat, Never>
    private var showInvisibleCharacters: Bool {
        invisibleCharacterSettings.showTabs.value
            || invisibleCharacterSettings.showSpaces.value
            || invisibleCharacterSettings.showLineBreaks.value
            || invisibleCharacterSettings.showSoftLineBreaks.value
    }

    init(
        lineFragment: LineFragment,
        invisibleCharacterSettings: InvisibleCharacterSettings,
        markedTextBackgroundColor: CurrentValueSubject<MultiPlatformColor, Never>,
        markedTextBackgroundCornerRadius: CurrentValueSubject<CGFloat, Never>
    ) {
        self.lineFragment = lineFragment
        self.invisibleCharacterSettings = invisibleCharacterSettings
        self.markedTextBackgroundColor = markedTextBackgroundColor
        self.markedTextBackgroundCornerRadius = markedTextBackgroundCornerRadius
    }

    func draw(to context: CGContext, inCanvasOfSize canvasSize: CGSize) {
        drawHighlightedRanges(to: context, inCanvasOfSize: canvasSize)
        drawMarkedRange(to: context)
        drawInvisibleCharacters()
        drawText(to: context)
    }
}

private extension LineFragmentRenderer {
    private func drawHighlightedRanges(to context: CGContext, inCanvasOfSize canvasSize: CGSize) {
        guard !highlightedRangeFragments.isEmpty else {
            return
        }
        context.saveGState()
        for highlightedRange in highlightedRangeFragments {
            let startX = CTLineGetOffsetForStringIndex(lineFragment.line, highlightedRange.range.lowerBound, nil)
            let endX: CGFloat
            if shouldHighlightLineEnding(for: highlightedRange) {
                endX = canvasSize.width
            } else {
                endX = CTLineGetOffsetForStringIndex(lineFragment.line, highlightedRange.range.upperBound, nil)
            }
            let cornerRadius = highlightedRange.cornerRadius
            let rect = CGRect(x: startX, y: 0, width: endX - startX, height: lineFragment.scaledSize.height)
            let roundedPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            context.setFillColor(highlightedRange.color.cgColor)
            context.addPath(roundedPath)
            context.fillPath()
            // Draw non-rounded edges if needed.
            if !highlightedRange.containsStart {
                let startRect = CGRect(x: 0, y: 0, width: cornerRadius, height: rect.height)
                let startPath = CGPath(rect: startRect, transform: nil)
                context.addPath(startPath)
                context.fillPath()
            }
            if !highlightedRange.containsEnd {
                let endRect = CGRect(x: 0, y: 0, width: rect.width - cornerRadius, height: rect.height)
                let endPath = CGPath(rect: endRect, transform: nil)
                context.addPath(endPath)
                context.fillPath()
            }
        }
        context.restoreGState()
    }

    private func drawMarkedRange(to context: CGContext) {
        if let markedRange = markedRange {
            context.saveGState()
            let startX = CTLineGetOffsetForStringIndex(lineFragment.line, markedRange.lowerBound, nil)
            let endX = CTLineGetOffsetForStringIndex(lineFragment.line, markedRange.upperBound, nil)
            let rect = CGRect(x: startX, y: 0, width: endX - startX, height: lineFragment.scaledSize.height)
            context.setFillColor(markedTextBackgroundColor.value.cgColor)
            if markedTextBackgroundCornerRadius.value > 0 {
                let cornerRadius = markedTextBackgroundCornerRadius.value
                let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                context.addPath(path)
                context.fillPath()
            } else {
                context.fill(rect)
            }
            context.restoreGState()
        }
    }

    private func drawInvisibleCharacters() {
        if showInvisibleCharacters, let string = delegate?.string(in: self) {
            drawInvisibleCharacters(in: string)
        }
    }

    private func drawText(to context: CGContext) {
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: lineFragment.scaledSize.height)
        context.scaleBy(x: 1, y: -1)
        let yPosition = lineFragment.descent + (lineFragment.scaledSize.height - lineFragment.baseSize.height) / 2
        context.textPosition = CGPoint(x: 0, y: yPosition)
        CTLineDraw(lineFragment.line, context)
        context.restoreGState()
    }

    private func drawInvisibleCharacters(in string: String) {
        var indexInLineFragment = 0
        for substring in string {
            let indexInLine = lineFragment.visibleRange.location + indexInLineFragment
            indexInLineFragment += substring.utf16.count
            if invisibleCharacterSettings.showSpaces.value && substring == Symbol.Character.space {
                draw(invisibleCharacterSettings.spaceSymbol.value, at: .character(indexInLine))
            } else if invisibleCharacterSettings.showNonBreakingSpaces.value && substring == Symbol.Character.nonBreakingSpace {
                draw(invisibleCharacterSettings.nonBreakingSpaceSymbol.value, at: .character(indexInLine))
            } else if invisibleCharacterSettings.showTabs.value && substring == Symbol.Character.tab {
                draw(invisibleCharacterSettings.tabSymbol.value, at: .character(indexInLine))
            } else if invisibleCharacterSettings.showLineBreaks.value && isLineBreak(substring) {
                draw(invisibleCharacterSettings.lineBreakSymbol.value, at: .endOfLine)
            } else if invisibleCharacterSettings.showSoftLineBreaks.value && substring == Symbol.Character.lineSeparator {
                draw(invisibleCharacterSettings.softLineBreakSymbol.value, at: .endOfLine)
            }
        }
    }

    private func draw(_ symbol: String, at horizontalPosition: HorizontalPosition) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: invisibleCharacterSettings.textColor.value,
            .font: invisibleCharacterSettings.font.value,
            .paragraphStyle: paragraphStyle
        ]
        let size = symbol.size(withAttributes: attrs)
        let xPosition = xPositionDrawingSymbol(ofSize: size, at: horizontalPosition)
        let yPosition = (lineFragment.scaledSize.height - size.height) / 2
        let rect = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
        symbol.draw(in: rect, withAttributes: attrs)
    }

    private func xPositionDrawingSymbol(ofSize symbolSize: CGSize, at horizontalPosition: HorizontalPosition) -> CGFloat {
        switch horizontalPosition {
        case .character(let index):
            let minX = CTLineGetOffsetForStringIndex(lineFragment.line, index, nil)
            if index < lineFragment.range.upperBound {
                let maxX = CTLineGetOffsetForStringIndex(lineFragment.line, index + 1, nil)
                return minX + (maxX - minX - symbolSize.width) / 2
            } else {
                return minX
            }
        case .endOfLine:
            return CGFloat(CTLineGetTypographicBounds(lineFragment.line, nil, nil, nil))
        }
    }

    private func shouldHighlightLineEnding(for highlightedRangeFragment: HighlightedRangeFragment) -> Bool {
        guard highlightedRangeFragment.range.upperBound == lineFragment.range.upperBound else {
            return false
        }
        guard let string = delegate?.string(in: self), let lastCharacter = string.last else {
            return false
        }
        return isLineBreak(lastCharacter)
    }

    private func isLineBreak(_ string: String.Element) -> Bool {
        string == Symbol.Character.lineFeed || string == Symbol.Character.carriageReturn || string == Symbol.Character.carriageReturnLineFeed
    }
}
