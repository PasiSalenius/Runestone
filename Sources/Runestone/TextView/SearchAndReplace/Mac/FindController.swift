#if os(macOS)
import AppKit

@available(macOS 12, *)
final class FindController: NSObject {
    static let shared = FindController()

    weak var textView: TextView? {
        didSet {
            // Even if no search is active, update replace button state
            updateReplaceButtonState()

            guard textView != oldValue else { return }
            
            oldValue?.highlightedRanges.removeAll()
            
            // When switching to a different text view, re-run the search
            if findPanelWindow.isVisible, !searchQuery.isEmpty {
                performSearch(query: searchQuery, options: searchOptions)
            }
        }
    }

    private var findPanel: FindPanel
    private var findPanelWindow: NSWindow
    private var searchResults: [SearchResult] = []
    private var searchResultIndex = 0
    private var searchQuery = ""
    private var searchOptions = FindPanel.SearchOptions()

    private let autosaveName = NSWindow.FrameAutosaveName("findPanel")

    // Background queue for search operations to prevent UI blocking
    private let searchQueue = OperationQueue()
    private var currentSearchOperation: Operation?

    // Maximum number of highlights to display for performance
    private let maxVisibleHighlights = 1000

    private override init() {
        let panel = FindPanel()
        findPanel = panel

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 100),
            styleMask: [.titled, .miniaturizable, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Find"
        window.contentView = panel
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        window.collectionBehavior = [.managed, .participatesInCycle, .fullScreenNone]

        window.setFrameAutosaveName(autosaveName)
        if !window.setFrameUsingName(autosaveName, force: false) {
            window.center()
        }

        findPanelWindow = window

        // Private init to enforce singleton
        searchQueue.qualityOfService = .userInitiated
        searchQueue.maxConcurrentOperationCount = 1
        
        super.init()
        
        panel.delegate = self
        window.delegate = self
        
        updateReplaceButtonState()
    }

    // MARK: - Public Methods

    func showFindPanel() {
        findPanelWindow.makeKeyAndOrderFront(nil)
        findPanel.focusSearchField()
        updateReplaceButtonState()
        
        // Restore previous search query if one exists
        if !searchQuery.isEmpty {
            findPanel.setSearchString(searchQuery)
        }
    }

    func focusSearchField() {
        findPanel.focusSearchField()
    }

    func setSearchString(_ string: String) {
        findPanel.setSearchString(string)
    }

    func hideFindPanel() {
        findPanelWindow.close()
        clearSearchHighlights()
    }

    func findNext() {
        performFind(forward: true)
    }

    func findPrevious() {
        performFind(forward: false)
    }

    /// Refreshes the current search. Call this when the text content changes.
    func refreshSearch() {
        guard findPanelWindow.isVisible else { return }

        if searchQuery.isEmpty {
            // Clear any existing highlights if there's no active search
            clearSearchHighlights()
            searchResults = []
            searchResultIndex = 0
            findPanel.updateMatchCount(current: 0, total: 0)
        } else {
            // Re-run the search with current query
            performSearch(query: searchQuery, options: searchOptions)
        }
    }

    // MARK: - Private Methods

    private func performFind(forward: Bool) {
        guard !searchResults.isEmpty else { return }

        if forward {
            searchResultIndex = (searchResultIndex + 1) % searchResults.count
        } else {
            searchResultIndex = (searchResultIndex - 1 + searchResults.count) % searchResults.count
        }

        updateHighlights()
        scrollToCurrentMatch()
        updateMatchCountDisplay()
    }

    private func performSearch(query: String, options: FindPanel.SearchOptions) {
        guard let textView else { return }

        // Store current query and options
        searchQuery = query
        searchOptions = options

        guard !query.isEmpty else {
            // Handle empty query synchronously on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.clearSearchHighlights()
                self.searchResults = []
                self.searchResultIndex = 0
                self.findPanel.updateMatchCount(current: 0, total: 0)
            }
            return
        }

        // Cancel any existing search operation
        currentSearchOperation?.cancel()

        // Create a new search operation to run in the background
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self, weak operation, weak textView] in
            guard let self, let operation, let textView, !operation.isCancelled else {
                return
            }

            // Prepare search query
            let matchMethod: SearchQuery.MatchMethod
            if options.isRegularExpression {
                matchMethod = .regularExpression
            } else {
                matchMethod = options.matchMethod
            }

            let searchQuery = SearchQuery(
                text: query,
                matchMethod: matchMethod,
                isCaseSensitive: options.isCaseSensitive
            )

            // Perform search on background thread
            let searchResults = textView.search(for: searchQuery)

            // Check if cancelled before updating UI
            guard !operation.isCancelled else { return }

            // Get selected range for positioning
            let selectedRange = textView.selectedRange()

            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Verify this search is still relevant (query hasn't changed)
                guard self.searchQuery == query else { return }

                self.searchResults = searchResults

                if !searchResults.isEmpty {
                    // Find the index of the first result after the current selection
                    if let index = searchResults.firstIndex(where: { $0.range.location >= selectedRange.location }) {
                        self.searchResultIndex = index
                    } else {
                        self.searchResultIndex = 0
                    }
                } else {
                    self.searchResultIndex = 0
                }

                self.updateHighlights()
                if !searchResults.isEmpty {
                    self.scrollToCurrentMatch()
                }
                self.updateMatchCountDisplay()
                self.updateReplaceButtonState()
            }
        }

        currentSearchOperation = operation
        searchQueue.addOperation(operation)
    }

    private func updateReplaceButtonState() {
        guard let textView else {
            findPanel.setReplaceEnabled(false)
            return
        }

        // Check if we can replace by asking the delegate
        // Use a dummy highlighted range to check permission
        let dummyRange = HighlightedRange(range: NSRange(location: 0, length: 0), color: .clear)
        let canReplace = textView.editorDelegate?.textView(textView, canReplaceTextIn: dummyRange) ?? true

        findPanel.setReplaceEnabled(canReplace)
    }

    private func updateHighlights() {
        guard let textView else { return }

        // Clear existing highlights
        textView.highlightedRanges.removeAll()

        guard !searchResults.isEmpty else { return }

        // Limit the number of visible highlights for performance
        // We still keep all results in searchResults for navigation and count display
        let highlightCount = min(searchResults.count, maxVisibleHighlights)

        // Add highlights for matches up to the limit
        for index in 0..<highlightCount {
            let result = searchResults[index]
            let isSelected = index == searchResultIndex
            if let highlightedRange = textView.theme.highlightedRange(forFoundTextRange: result.range, isSelected: isSelected) {
                textView.highlightedRanges.append(highlightedRange)
            }
        }
    }

    private func clearSearchHighlights() {
        textView?.highlightedRanges.removeAll()
    }

    private func scrollToCurrentMatch() {
        guard searchResultIndex < searchResults.count else { return }
        let result = searchResults[searchResultIndex]
        textView?.scrollRangeToVisible(result.range)
    }

    private func updateMatchCountDisplay() {
        let current = searchResults.isEmpty ? 0 : searchResultIndex + 1
        let total = searchResults.count
        findPanel.updateMatchCount(current: current, total: total)
    }
}

// MARK: - FindPanelDelegate
@available(macOS 12, *)
extension FindController: FindPanelDelegate {
    func findPanel(_ panel: FindPanel, didUpdateSearchQuery query: String, options: FindPanel.SearchOptions) {
        performSearch(query: query, options: options)
    }

    func findPanel(_ panel: FindPanel, didRequestFindNext forward: Bool) {
        performFind(forward: forward)
    }

    func findPanel(_ panel: FindPanel, didRequestReplace range: NSRange, with text: String) {
        guard let textView else { return }

        // Replace the currently selected/highlighted match
        guard searchResultIndex < searchResults.count else { return }
        let matchRange = searchResults[searchResultIndex].range

        // Check if we can replace
        if let highlightedRange = textView.highlightedRanges.first(where: { $0.range == matchRange }) {
            if let canReplace = textView.editorDelegate?.textView(textView, canReplaceTextIn: highlightedRange), !canReplace {
                return
            }
        }

        // Perform the replacement
        textView.replace(matchRange, withText: text)

        // Re-run search to update results after replacement
        if !searchQuery.isEmpty {
            performSearch(query: searchQuery, options: searchOptions)
            // After re-searching, move to next match if there are still results
            if !searchResults.isEmpty {
                performFind(forward: true)
            }
        }
    }

    func findPanel(_ panel: FindPanel, didRequestReplaceAll query: String, with text: String, options: FindPanel.SearchOptions) {
        guard let textView else { return }

        let matchMethod: SearchQuery.MatchMethod
        if options.isRegularExpression {
            matchMethod = .regularExpression
        } else {
            matchMethod = options.matchMethod
        }

        let searchQuery = SearchQuery(
            text: query,
            matchMethod: matchMethod,
            isCaseSensitive: options.isCaseSensitive
        )

        let results = textView.search(for: searchQuery, replacingMatchesWith: text)

        // Check with delegate if we can replace
        for result in results {
            let highlightedRange = HighlightedRange(range: result.range, color: .clear)
            if let canReplace = textView.editorDelegate?.textView(textView, canReplaceTextIn: highlightedRange), !canReplace {
                return
            }
        }

        let replacements = results.map { BatchReplaceSet.Replacement(range: $0.range, text: $0.replacementText) }
        let batchReplaceSet = BatchReplaceSet(replacements: replacements)
        textView.replaceText(in: batchReplaceSet)

        // Clear search results and update display
        searchResults = []
        searchResultIndex = 0
        clearSearchHighlights()
        panel.updateMatchCount(current: 0, total: 0)
    }
}

// MARK: - NSWindowDelegate
@available(macOS 12, *)
extension FindController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        clearSearchHighlights()
    }
}

#endif
