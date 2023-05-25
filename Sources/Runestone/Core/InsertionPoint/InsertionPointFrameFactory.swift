import Combine
import CoreText
import Foundation

final class InsertionPointFrameFactory {
    private let lineManager: CurrentValueSubject<LineManager, Never>
    private let characterBoundsProvider: CharacterBoundsProvider
    private let lineControllerStorage: LineControllerStorage
    private let insertionPointShape: CurrentValueSubject<InsertionPointShape, Never>
    private let estimatedLineHeight: EstimatedLineHeight
    private let estimatedCharacterWidth: CurrentValueSubject<CGFloat, Never>
    private var contentArea: CGRect = .zero
    private var cancellables: Set<AnyCancellable> = []

    init(
        lineManager: CurrentValueSubject<LineManager, Never>,
        characterBoundsProvider: CharacterBoundsProvider,
        lineControllerStorage: LineControllerStorage,
        insertionPointShape: CurrentValueSubject<InsertionPointShape, Never>,
        contentArea: AnyPublisher<CGRect, Never>,
        estimatedLineHeight: EstimatedLineHeight,
        estimatedCharacterWidth: CurrentValueSubject<CGFloat, Never>
    ) {
        self.lineManager = lineManager
        self.characterBoundsProvider = characterBoundsProvider
        self.lineControllerStorage = lineControllerStorage
        self.insertionPointShape = insertionPointShape
        self.estimatedLineHeight = estimatedLineHeight
        self.estimatedCharacterWidth = estimatedCharacterWidth
        contentArea.sink { [weak self] contentArea in
            self?.contentArea = contentArea
        }.store(in: &cancellables)
    }

    func frameOfInsertionPoint(at location: Int) -> CGRect {
        switch insertionPointShape.value {
        case .verticalBar:
            return verticalBarInsertionPointFrame(at: location)
        case .underline:
            return underlineInsertionPointFrame(at: location)
        case .block:
            return blockInsertionPointFrame(at: location)
        }
    }
}

extension InsertionPointFrameFactory {
    private var fixedLength: CGFloat {
        #if os(iOS)
        return 2
        #else
        return 1
        #endif
    }

    private func verticalBarInsertionPointFrame(at location: Int) -> CGRect {
        let blockFrame = blockInsertionPointFrame(at: location)
        return CGRect(x: blockFrame.minX, y: blockFrame.minY, width: fixedLength, height: blockFrame.height)
    }

    private func underlineInsertionPointFrame(at location: Int) -> CGRect {
        let blockFrame = blockInsertionPointFrame(at: location)
        return CGRect(x: blockFrame.minX, y: blockFrame.maxY - fixedLength, width: blockFrame.width, height: fixedLength)
    }

    private func blockInsertionPointFrame(at location: Int) -> CGRect {
        if let bounds = characterBoundsProvider.boundsOfComposedCharacterSequence(atLocation: location, moveToToNextLineFragmentIfNeeded: true) {
            let width = displayableCharacterWidth(forCharacterAtLocation: location, widthActualWidth: bounds.width)
            return CGRect(x: bounds.minX, y: bounds.minY, width: width, height: bounds.height)
        } else {
            let size = CGSize(width: estimatedCharacterWidth.value, height: estimatedLineHeight.rawValue.value)
            let offsetOrigin = CGPoint(x: contentArea.origin.x, y: contentArea.origin.y + (estimatedLineHeight.scaledValue.value - size.height) / 2)
            return CGRect(origin: offsetOrigin, size: size)
        }
    }

    private func displayableCharacterWidth(forCharacterAtLocation location: Int, widthActualWidth actualWidth: CGFloat) -> CGFloat {
        guard let line = lineManager.value.line(containingCharacterAt: location) else {
            return actualWidth
        }
        // If the insertion point is placed at the last character in a line, i.e. before a line break, then we make sure to return the estimated character width.
        let lineLocalLocation = location - line.location
        if lineLocalLocation == line.data.length {
            return estimatedCharacterWidth.value
        } else {
            return actualWidth
        }
    }
}
