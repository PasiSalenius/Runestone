import _RunestoneMultiPlatform
import _RunestoneObservation
import Foundation

@RunestoneObservable @RunestoneObserver
final class ScrollViewMaximumLineFragmentWidthProvider: MaximumLineFragmentWidthProviding {
    typealias State = TextContainerInsetReadable

    private(set) var maximumLineFragmentWidth: CGFloat = 0

    private var textContainerInset: MultiPlatformEdgeInsets {
        didSet {
            if textContainerInset != oldValue {
                recompute()
            }
        }
    }
    private var size: CGSize {
        didSet {
            if size != oldValue {
                recompute()
            }
        }
    }

    init(state: some State, viewport: some Viewport) {
        textContainerInset = state.textContainerInset
        size = viewport.size
        recompute()
        observe(state.textContainerInset) { [weak self] _, newValue in
            self?.textContainerInset = newValue
        }
        observe(viewport.size) { [weak self] _, newValue in
            self?.size = newValue
        }
    }
}

private extension ScrollViewMaximumLineFragmentWidthProvider {
    private func recompute() {
        maximumLineFragmentWidth = size.width - textContainerInset.left - textContainerInset.right
    }
}
