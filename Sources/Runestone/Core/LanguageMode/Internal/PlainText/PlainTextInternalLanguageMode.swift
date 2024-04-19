import Combine
import Foundation

final class PlainTextInternalLanguageMode<LineType: Line>: InternalLanguageMode {
    private let operationQueue = OperationQueue()

    init() {
        operationQueue.name = "TreeSitterLanguageMode"
        operationQueue.qualityOfService = .userInitiated
    }

    deinit {
        operationQueue.cancelAllOperations()
    }

    func parse(_ text: NSString) {}

    func parse(_ text: NSString, completion: @escaping ((Bool) -> Void)) {
        completion(true)
    }

    func textDidChange(_ change: TextEdit<LineType>) -> LineChangeSet<LineType> {
        LineChangeSet()
    }

    func tokenType(at location: Int) -> String? {
        nil
    }

    func createSyntaxHighlighter(with theme: Theme) -> any SyntaxHighlighter {
        PlainTextSyntaxHighlighter(operationQueue: operationQueue)
    }

    func highestSyntaxNode(at linePosition: LinePosition) -> SyntaxNode? {
        nil
    }

    func syntaxNode(at linePosition: LinePosition) -> SyntaxNode? {
        nil
    }

    func strategyForInsertingLineBreak(
        from startLinePosition: LinePosition,
        to endLinePosition: LinePosition,
        using indentStrategy: IndentStrategy
    ) -> InsertLineBreakIndentStrategy {
        InsertLineBreakIndentStrategy(indentLevel: 0, insertExtraLineBreak: false)
    }

    func detectIndentStrategy() -> DetectedIndentStrategy {
        .unknown
    }
}