#if os(macOS)
import AppKit

// MARK: - NSTextFinder Bridge (Available on all macOS versions)
extension TextView {
    /// Bridge NSTextFinder actions to custom find implementation
    @objc override public func performTextFinderAction(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else {
            super.performTextFinderAction(sender)
            return
        }

        guard let action = NSTextFinder.Action(rawValue: menuItem.tag) else {
            super.performTextFinderAction(sender)
            return
        }

        switch action {
        case .showFindInterface:
            showFindPanel(sender)
        case .showReplaceInterface:
            showFindPanel(sender)
        case .nextMatch:
            findNext(sender)
        case .previousMatch:
            findPrevious(sender)
        case .replace, .replaceAndFind:
            showFindPanel(sender)
        case .replaceAll:
            showFindPanel(sender)
        case .hideFindInterface:
            hideFindPanel(sender)
        case .setSearchString:
            useSelectionForFind(sender)
        default:
            super.performTextFinderAction(sender)
        }
    }
}

extension TextView {
    private var findController: FindController {
        FindController.shared
    }

    /// Shows the find panel
    @objc public func showFindPanel(_ sender: Any?) {
        findController.textView = self
        findController.showFindPanel()
    }

    /// Hides the find panel
    @objc public func hideFindPanel(_ sender: Any?) {
        findController.hideFindPanel()
    }

    /// Finds the next occurrence
    @objc public func findNext(_ sender: Any?) {
        findController.textView = self
        findController.findNext()
    }

    /// Finds the previous occurrence
    @objc public func findPrevious(_ sender: Any?) {
        findController.textView = self
        findController.findPrevious()
    }

    /// Refreshes the find panel search results. Call this when the text content changes.
    @objc public func refreshFindPanelSearch() {
        if findController.textView === self {
            // This text view is being searched - refresh the search
            findController.refreshSearch()
        } else {
            // This text view is not being searched - just clear any old highlights
            highlightedRanges.removeAll()
        }
    }

    /// Called when this text view becomes first responder
    internal func notifyFindControllerDidBecomeFocused() {
        // Update the find controller to search this text view
        findController.textView = self
    }

    /// Uses the current selection as the search string
    @objc public func useSelectionForFind(_ sender: Any?) {
        findController.textView = self
        let range = selectedRange()
        if let selection = text(in: range), !selection.isEmpty {
            findController.showFindPanel()
            findController.setSearchString(selection)
        }
    }
}

#endif
