import _RunestoneMultiPlatform
import Combine
import Foundation

final class LineSelectionLayouter<LineManagerType: LineManaging> {
    let lineSelectionDisplayType = CurrentValueSubject<LineSelectionDisplayType, Never>(.disabled)

    private let lineSelectionView = MultiPlatformView()
    private var cancellables: Set<AnyCancellable> = []

//    init(
//        selectedRange: CurrentValueSubject<NSRange, Never>,
//        lineManager: LineManagerType,
//        viewport: CurrentValueSubject<CGRect, Never>,
//        textContainerInset: CurrentValueSubject<MultiPlatformEdgeInsets, Never>,
//        lineHeightMultiplier: CurrentValueSubject<CGFloat, Never>,
//        backgroundColor: CurrentValueSubject<MultiPlatformColor, Never>,
//        containerView: CurrentValueSubject<WeakBox<TextView>, Never>
//    ) {
//        lineSelectionView.layerIfLoaded?.zPosition = -1000
//        containerView.value.value?.addSubview(lineSelectionView)
//        setupBackgroundColorSubscriber(backgroundColor: backgroundColor)
//        setupHiddenSubscriber(
//            lineSelectionDisplayType: lineSelectionDisplayType,
//            selectedRange: selectedRange
//        )
//        setupFrameSubscriber(
//            lineSelectionDisplayType: lineSelectionDisplayType,
//            selectedRange: selectedRange,
//            lineManager: lineManager,
//            viewport: viewport,
//            textContainerInset: textContainerInset,
//            lineHeightMultiplier: lineHeightMultiplier
//        )
//    }
}

private extension LineSelectionLayouter {
    private func setupBackgroundColorSubscriber(backgroundColor: CurrentValueSubject<MultiPlatformColor, Never>) {
        backgroundColor.sink { [weak self] color in
            self?.lineSelectionView.backgroundColor = color
        }.store(in: &cancellables)
    }

    private func setupHiddenSubscriber(
        lineSelectionDisplayType: CurrentValueSubject<LineSelectionDisplayType, Never>,
        selectedRange: CurrentValueSubject<NSRange, Never>
    ) {
        Publishers.CombineLatest(lineSelectionDisplayType, selectedRange).sink { [weak self] lineSelectionDisplayType, selectedRange in
            self?.lineSelectionView.isHidden = lineSelectionDisplayType == .disabled || selectedRange.length > 0
        }.store(in: &cancellables)
    }

    private func setupFrameSubscriber(
        lineSelectionDisplayType: CurrentValueSubject<LineSelectionDisplayType, Never>,
        selectedRange: CurrentValueSubject<NSRange, Never>,
        lineManager: LineManagerType,
        viewport: CurrentValueSubject<CGRect, Never>,
        textContainerInset: CurrentValueSubject<MultiPlatformEdgeInsets, Never>,
        lineHeightMultiplier: CurrentValueSubject<CGFloat, Never>
    ) {
//        Publishers.CombineLatest(
//            Publishers.CombineLatest(lineSelectionDisplayType, selectedRange),
//            Publishers.CombineLatest3(viewport, textContainerInset, lineHeightMultiplier)
//        ).sink { [weak self] tupleA, tupleB in
//            guard let self else {
//                return
//            }
//            let (lineSelectionDisplayType, selectedRange, lineManager) = tupleA
//            let (viewport, textContainerInset, lineHeightMultiplier) = tupleB
//            let rectFactory = LineSelectionRectFactory(
//                viewport: viewport,
//                caret: self.caret,
//                lineManager: lineManager,
//                lineSelectionDisplayType: lineSelectionDisplayType,
//                textContainerInset: textContainerInset,
//                lineHeightMultiplier: lineHeightMultiplier,
//                selectedRange: selectedRange
//            )
//            if let frame = rectFactory.rect {
//                self.lineSelectionView.frame = frame
//            }
//        }.store(in: &cancellables)
    }
}
