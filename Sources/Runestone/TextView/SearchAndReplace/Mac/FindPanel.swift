#if os(macOS)
import AppKit

/// Delegate protocol for find panel interactions
protocol FindPanelDelegate: AnyObject {
    func findPanel(_ panel: FindPanel, didUpdateSearchQuery query: String, options: FindPanel.SearchOptions)
    func findPanel(_ panel: FindPanel, didRequestFindNext: Bool)
    func findPanel(_ panel: FindPanel, didRequestReplace range: NSRange, with text: String)
    func findPanel(_ panel: FindPanel, didRequestReplaceAll query: String, with text: String, options: FindPanel.SearchOptions)
}

/// A custom find panel for searching and replacing text in a TextView
final class FindPanel: NSView {
    struct SearchOptions {
        var isCaseSensitive: Bool = false
        var isRegularExpression: Bool = false
        var matchMethod: SearchQuery.MatchMethod = .contains
    }

    weak var delegate: FindPanelDelegate?

    private let searchField = NSSearchField()
    private let replaceField = NSSearchField()
    private let replaceButton = NSButton()
    private let replaceAllButton = NSButton()
    private let matchCountLabel = NSTextField(labelWithString: "")

    private let searchAutosaveName = "findPanel"
    
    private let navigationControl = NSSegmentedControl()

    private let ignoreCaseCheckbox = NSButton(checkboxWithTitle: "Ignore Case", target: nil, action: nil)
    private let searchModeLabel = NSTextField()
    private let searchModePopup = NSPopUpButton()

    private var searchOptions = SearchOptions()

    // MARK: - Initialization
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        searchField.placeholderString = "Find"
        searchField.bezelStyle = .squareBezel
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchFieldDidChange(_:))
        
        searchField.maximumRecents = 10
        searchField.searchMenuTemplate = recentsSearchesMenu()
        searchField.recentsAutosaveName = searchAutosaveName
        searchField.recentSearches = UserDefaults.standard.array(forKey: searchAutosaveName) as? [String] ?? []

        replaceField.placeholderString = "Replace"
        replaceField.bezelStyle = .squareBezel
        replaceField.isHidden = false

        if let cell = replaceField.cell as? NSSearchFieldCell {
            let pencilImage = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
            cell.searchButtonCell?.image = pencilImage
            // Enable the search menu to match the width of the search field's button
            cell.searchMenuTemplate = NSMenu()
        }

        navigationControl.controlSize = .regular
        navigationControl.target = self
        navigationControl.action = #selector(navigationAction)
        navigationControl.font = .preferredFont(forTextStyle: .subheadline)
        navigationControl.segmentStyle = .rounded
        navigationControl.trackingMode = .momentary
        
        navigationControl.segmentCount = 2
        
        let previousImage = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        navigationControl.setImage(previousImage, forSegment: 0)
        navigationControl.setWidth(40, forSegment: 0)

        let nextImage = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        navigationControl.setImage(nextImage, forSegment: 1)
        navigationControl.setWidth(40, forSegment: 1)

        replaceButton.title = "Replace"
        replaceButton.bezelStyle = .rounded
        replaceButton.target = self
        replaceButton.action = #selector(replace(_:))

        replaceAllButton.title = "Replace All"
        replaceAllButton.bezelStyle = .rounded
        replaceAllButton.target = self
        replaceAllButton.action = #selector(replaceAll(_:))

        matchCountLabel.isEditable = false
        matchCountLabel.isBordered = false
        matchCountLabel.drawsBackground = false
        matchCountLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        matchCountLabel.textColor = .secondaryLabelColor
        matchCountLabel.alignment = .right
        
        matchCountLabel.setContentHuggingPriority(.init(rawValue: 1), for: .horizontal)

        ignoreCaseCheckbox.target = self
        ignoreCaseCheckbox.action = #selector(optionDidChange(_:))
        
        searchModeLabel.stringValue = "Mode:"
        searchModeLabel.textColor = .labelColor
        searchModeLabel.drawsBackground = false
        searchModeLabel.isBordered = false
        searchModeLabel.isEditable = false
        searchModeLabel.isSelectable = false

        searchModePopup.addItem(withTitle: "Contains")
        searchModePopup.addItem(withTitle: "Starts With")
        searchModePopup.addItem(withTitle: "Ends With")
        searchModePopup.addItem(withTitle: "Full Word")
        searchModePopup.addItem(withTitle: "Regular Expression")
        searchModePopup.target = self
        searchModePopup.action = #selector(optionDidChange(_:))

        // Set default values to match SearchOptions defaults
        // isCaseSensitive = false means Ignore Case should be ON (checked)
        ignoreCaseCheckbox.state = .on
        // matchMethod = .contains means "Contains" (index 0) should be selected
        searchModePopup.selectItem(at: 0)

        let optionsStack = NSStackView(views: [
            ignoreCaseCheckbox,
            NSView(),
            searchModeLabel,
            searchModePopup,
        ])

        optionsStack.orientation = .horizontal
        optionsStack.spacing = 5

        let bottomStack = NSStackView(views: [
            replaceAllButton,
            replaceButton,
            matchCountLabel,
            navigationControl,
        ])
        
        bottomStack.orientation = .horizontal
        bottomStack.spacing = 12
        
        let stackView = NSStackView(views: [
            searchField,
            replaceField,
            optionsStack,
            bottomStack,
        ])
        
        stackView.orientation = .vertical
        stackView.spacing = 20
        
        stackView.setCustomSpacing(10, after: searchField)
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
            focusSearchField()
            return true
        }

        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "g" {
            if event.modifierFlags.contains(.shift) {
                findPrevious(self)
            } else {
                findNext(self)
            }
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
    
    private func recentsSearchesMenu() -> NSMenu {
        let menu = NSMenu(title: "Recent")

        let recentTitleItem = menu.addItem(withTitle: "Recent Searches", action: nil, keyEquivalent: "")
        recentTitleItem.tag = Int(NSSearchField.recentsTitleMenuItemTag)

        let placeholder = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        placeholder.tag = Int(NSSearchField.recentsMenuItemTag)

        menu.addItem(NSMenuItem.separator())

        let clearItem = menu.addItem(withTitle: "Clear Recent Searches", action: nil, keyEquivalent: "")
        clearItem.tag = Int(NSSearchField.clearRecentsMenuItemTag)

        let emptyItem = menu.addItem(withTitle: "No Recent Searches", action: nil, keyEquivalent: "")
        emptyItem.tag = Int(NSSearchField.noRecentsMenuItemTag)

        return menu
    }
    
    // MARK: - Public Methods
    func updateMatchCount(current: Int, total: Int) {
        if total > 0 {
            matchCountLabel.stringValue = "\(current) of \(total)"
        } else if !searchField.stringValue.isEmpty {
            matchCountLabel.stringValue = "No matches"
        } else {
            matchCountLabel.stringValue = ""
        }
    }

    func focusSearchField() {
        window?.makeFirstResponder(searchField)
        searchField.selectText(nil)
    }

    func setReplaceEnabled(_ enabled: Bool) {
        replaceButton.isEnabled = enabled
        replaceAllButton.isEnabled = enabled
    }

    func setSearchString(_ string: String) {
        searchField.stringValue = string
        updateSearchOptions()
        delegate?.findPanel(self, didUpdateSearchQuery: string, options: searchOptions)
        // Select the text in the search field
        searchField.selectText(nil)
    }

    // MARK: - Actions
    @objc private func searchFieldDidChange(_ sender: NSTextField) {
        updateSearchOptions()
        delegate?.findPanel(self, didUpdateSearchQuery: sender.stringValue, options: searchOptions)
    }
    
    @objc private func navigationAction(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            findPrevious(self)
        case 1:
            findNext(self)
        default:
            break
        }
    }

    @objc private func findPrevious(_ sender: Any) {
        delegate?.findPanel(self, didRequestFindNext: false)
    }

    @objc private func findNext(_ sender: Any) {
        delegate?.findPanel(self, didRequestFindNext: true)
    }

    @objc private func replace(_ sender: Any) {
        // Get current selection/highlighted range
        // This will be handled by the delegate
        let replacementText = replaceField.stringValue
        // The delegate needs to determine which range to replace
        // For now, we'll pass NSRange(location: NSNotFound, length: 0) as a placeholder
        // The delegate should replace the currently selected/highlighted match
        delegate?.findPanel(self, didRequestReplace: NSRange(location: NSNotFound, length: 0), with: replacementText)
    }

    @objc private func replaceAll(_ sender: Any) {
        let query = searchField.stringValue
        let replacementText = replaceField.stringValue
        updateSearchOptions()
        delegate?.findPanel(self, didRequestReplaceAll: query, with: replacementText, options: searchOptions)
    }

    @objc private func done(_ sender: Any) {
        window?.close()
    }

    @objc private func optionDidChange(_ sender: Any) {
        updateSearchOptions()
        delegate?.findPanel(self, didUpdateSearchQuery: searchField.stringValue, options: searchOptions)
    }

    private func updateSearchOptions() {
        // Ignore Case checkbox - inverted from isCaseSensitive
        searchOptions.isCaseSensitive = ignoreCaseCheckbox.state == .off

        // Search mode popup determines both match method and if it's a regex
        switch searchModePopup.indexOfSelectedItem {
        case 0: // Contains
            searchOptions.matchMethod = .contains
            searchOptions.isRegularExpression = false
        case 1: // Starts With
            searchOptions.matchMethod = .startsWith
            searchOptions.isRegularExpression = false
        case 2: // Ends With
            searchOptions.matchMethod = .endsWith
            searchOptions.isRegularExpression = false
        case 3: // Full Word
            searchOptions.matchMethod = .fullWord
            searchOptions.isRegularExpression = false
        case 4: // Regular Expression
            searchOptions.matchMethod = .regularExpression
            searchOptions.isRegularExpression = true
        default:
            searchOptions.matchMethod = .contains
            searchOptions.isRegularExpression = false
        }
    }
}

// MARK: - NSSearchFieldDelegate
extension FindPanel: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField === searchField {
            searchFieldDidChange(searchField)
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if obj.object as? NSTextField === searchField {
            let searchText = searchField.stringValue
            if !searchText.isEmpty && searchField.recentSearches.first != searchText {
                searchField.recentSearches.insert(searchText, at: 0)
            }
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if control === searchField {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Enter key pressed - find next
                findNext(control)
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                // Escape key pressed - close panel
                done(control)
                return true
            }
        }
        return false
    }
}
#endif
