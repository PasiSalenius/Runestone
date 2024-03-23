// swiftlint:disable file_length
#if os(macOS)
import AppKit
import Combine
import UniformTypeIdentifiers

// swiftlint:disable:next type_body_length
/// A type similiar to NSTextView with features commonly found in code editors.
///
/// `TextView` is a performant implementation of a text view with features such as showing line numbers, searching for text and replacing results, syntax highlighting, showing invisible characters and more.
///
/// The type does not subclass `NSTextView` but its interface is kept close to `NSTextView`.
///
/// When initially configuring the `TextView` with a theme, a language and the text to be shown, it is recommended to use the ``setState(_:addUndoAction:)`` function.
/// The function takes an instance of ``TextViewState`` as input which can be created on a background queue to avoid blocking the main queue while doing the initial parse of a text.
open class TextView: NSView, NSMenuItemValidation {
//    /// Delegate to receive callbacks for events triggered by the editor.
//    public weak var editorDelegate: TextViewDelegate? {
//        get {
//            textViewDelegate.delegate
//        }
//        set {
//            textViewDelegate.delegate = newValue
//        }
//    }
//    /// Returns a Boolean value indicating whether this object can become the first responder.
//    override public var acceptsFirstResponder: Bool {
//        true
//    }
//    /// A Boolean value indicating whether the view uses a flipped coordinate system.
//    override public var isFlipped: Bool {
//        true
//    }
//    /// A Boolean value that indicates whether the text view is editable.
//    @Proxy(\TextView.editorState.isEditable.value)
//    public var isEditable: Bool
//    /// Whether the text view is in a state where the contents can be edited.
//    public var isEditing: Bool {
//        editorState.isEditing.value
//    }
//    /// The text that the text view displays.
//    public var text: String {
//        get {
//            stringView.string as String
//        }
//        set {
//            textSetter.setText(newValue as NSString)
//        }
//    }
//    /// Colors and fonts to be used by the editor.
//    @Proxy(\TextView.themeSettings.theme.value)
//    public var theme: Theme
//    /// Character pairs are used by the editor to automatically insert a trailing character when the user types the leading character.
//    ///
//    /// Common usages of this includes the \" character to surround strings and { } to surround a scope.
//    @Proxy(\TextView.characterPairService.characterPairs)
//    public var characterPairs: [CharacterPair]
//    /// Determines what should happen to the trailing component of a character pair when deleting the leading component. Defaults to `disabled` meaning that nothing will happen.
//    @Proxy(\TextView.characterPairService.trailingComponentDeletionMode)
//    public var characterPairTrailingComponentDeletionMode: CharacterPairTrailingComponentDeletionMode
//    /// Enable to show line numbers in the gutter.
////    public var showLineNumbers: Bool {
////        get {
////            showLineNumbers
////        }
////        set {
////            showLineNumbers = newValue
////        }
////    }
//    /// Enable to show highlight the selected lines. The selection is only shown in the gutter when multiple lines are selected.
//    @Proxy(\TextView.lineSelectionLayouter.lineSelectionDisplayType.value)
//    public var lineSelectionDisplayType: LineSelectionDisplayType
//    /// The text view renders invisible tabs when enabled. The `tabsSymbol` is used to render tabs.
//    @Proxy(\TextView.invisibleCharacterSettings.showTabs.value)
//    public var showTabs: Bool
//    /// The text view renders invisible spaces when enabled.
//    ///
//    /// The `spaceSymbol` is used to render spaces.
//    @Proxy(\TextView.invisibleCharacterSettings.showSpaces.value)
//    public var showSpaces: Bool
//    /// The text view renders invisible spaces when enabled.
//    ///
//    /// The `nonBreakingSpaceSymbol` is used to render spaces.
//    @Proxy(\TextView.invisibleCharacterSettings.showNonBreakingSpaces.value)
//    public var showNonBreakingSpaces: Bool
//    /// The text view renders invisible line breaks when enabled.
//    ///
//    /// The `lineBreakSymbol` is used to render line breaks.
//    @Proxy(\TextView.invisibleCharacterSettings.showLineBreaks.value)
//    public var showLineBreaks: Bool
//    /// The text view renders invisible soft line breaks when enabled.
//    ///
//    /// The `softLineBreakSymbol` is used to render line breaks. These line breaks are typically represented by the U+2028 unicode character. Runestone does not provide any key commands for inserting these but supports rendering them.
//    @Proxy(\TextView.invisibleCharacterSettings.showSoftLineBreaks.value)
//    public var showSoftLineBreaks: Bool
//    /// Symbol used to display tabs.
//    ///
//    /// The value is only used when invisible tab characters is enabled. The default is ▸.
//    ///
//    /// Common characters for this symbol include ▸, ⇥, ➜, ➞, and ❯.
//    @Proxy(\TextView.invisibleCharacterSettings.tabSymbol.value)
//    public var tabSymbol: String
//    /// Symbol used to display spaces.
//    ///
//    /// The value is only used when showing invisible space characters is enabled. The default is ·.
//    ///
//    /// Common characters for this symbol include ·, •, and _.
//    @Proxy(\TextView.invisibleCharacterSettings.spaceSymbol.value)
//    public var spaceSymbol: String
//    /// Symbol used to display non-breaking spaces.
//    ///
//    /// The value is only used when showing invisible space characters is enabled. The default is ·.
//    ///
//    /// Common characters for this symbol include ·, •, and _.
//    @Proxy(\TextView.invisibleCharacterSettings.nonBreakingSpaceSymbol.value)
//    public var nonBreakingSpaceSymbol: String
//    /// Symbol used to display line break.
//    ///
//    /// The value is only used when showing invisible line break characters is enabled. The default is ¬.
//    ///
//    /// Common characters for this symbol include ¬, ↵, ↲, ⤶, and ¶.
//    @Proxy(\TextView.invisibleCharacterSettings.lineBreakSymbol.value)
//    public var lineBreakSymbol: String
//    /// Symbol used to display soft line breaks.
//    ///
//    /// The value is only used when showing invisible soft line break characters is enabled. The default is ¬.
//    ///
//    /// Common characters for this symbol include ¬, ↵, ↲, ⤶, and ¶.
//    @Proxy(\TextView.invisibleCharacterSettings.softLineBreakSymbol.value)
//    public var softLineBreakSymbol: String
//    /// The strategy used when indenting text.
//    @Proxy(\TextView.typesetSettings.indentStrategy.value)
//    public var indentStrategy: IndentStrategy
//    /// The amount of padding before the line numbers inside the gutter.
////    public var gutterLeadingPadding: CGFloat {
////        get {
////            gutterLeadingPadding
////        }
////        set {
////            gutterLeadingPadding = newValue
////        }
////    }
//    /// The amount of padding after the line numbers inside the gutter.
////    public var gutterTrailingPadding: CGFloat {
////        get {
////            gutterTrailingPadding
////        }
////        set {
////            gutterTrailingPadding = newValue
////        }
////    }
//    /// The minimum amount of characters to use for width calculation inside the gutter.
////    public var gutterMinimumCharacterCount: Int {
////        get {
////            gutterMinimumCharacterCount
////        }
////        set {
////            gutterMinimumCharacterCount = newValue
////        }
////    }
//    /// The amount of spacing surrounding the lines.
//    @Proxy(\TextView.textContainer.inset.value)
//    public var textContainerInset: NSEdgeInsets
//    /// When line wrapping is disabled, users can scroll the text view horizontally to see the entire line.
//    ///
//    /// Line wrapping is enabled by default.
//    @Proxy(\TextView.typesetSettings.isLineWrappingEnabled.value)
//    public var isLineWrappingEnabled: Bool
//    /// Line break mode for text view. The default value is .byWordWrapping meaning that wrapping occurs on word boundaries.
//    @Proxy(\TextView.typesetSettings.lineBreakMode.value)
//    public var lineBreakMode: LineBreakMode
//    /// Width of the gutter.
////    public var gutterWidth: CGFloat {
////        gutterWidthService.gutterWidth
////    }
//    /// The line-height is multiplied with the value.
//    @Proxy(\TextView.typesetSettings.lineHeightMultiplier.value)
//    public var lineHeightMultiplier: CGFloat
//    /// The number of points by which to adjust kern. The default value is 0 meaning that kerning is disabled.
//    @Proxy(\TextView.typesetSettings.kern.value)
//    public var kern: CGFloat
//    /// The text view shows a page guide when enabled. Use `pageGuideColumn` to specify the location of the page guide.
//    @Proxy(\TextView.pageGuideLayouter.isEnabled)
//    public var showPageGuide: Bool
//    /// Specifies the location of the page guide. Use `showPageGuide` to specify if the page guide should be shown.
//    @Proxy(\TextView.pageGuideLayouter.column)
//    public var pageGuideColumn: Int
//    /// Automatically scrolls the text view to show the caret when typing or moving the caret.
//    @Proxy(\TextView.automaticViewportScroller.isAutomaticScrollEnabled)
//    public var isAutomaticScrollEnabled: Bool
//    /// Amount of overscroll to add in the vertical direction.
//    ///
//    /// The overscroll is a factor of the scrollable area height and will not take into account any insets. 0 means no overscroll and 1 means an amount equal to the height of the text view. Detaults to 0.
//    @Proxy(\TextView.contentSizeService.verticalOverscrollFactor.value)
//    public var verticalOverscrollFactor: CGFloat
//    /// Amount of overscroll to add in the horizontal direction.
//    ///
//    /// The overscroll is a factor of the scrollable area height and will not take into account any insets or the width of the gutter. 0 means no overscroll and 1 means an amount equal to the width of the text view. Detaults to 0.
//    @Proxy(\TextView.contentSizeService.horizontalOverscrollFactor.value)
//    public var horizontalOverscrollFactor: CGFloat
//    /// Ranges in the text to be highlighted. The color defined by the background will be drawen behind the text.
//    @Proxy(\TextView.highlightedRangeFragmentStore.highlightedRanges.value)
//    public var highlightedRanges: [HighlightedRange]
//    /// Wheter the text view should loop when navigating through highlighted ranges using `selectPreviousHighlightedRange` or `selectNextHighlightedRange` on the text view.
//    @Proxy(\TextView.highlightedRangeNavigator.loopingMode)
//    public var highlightedRangeLoopingMode: HighlightedRangeLoopingMode
//    /// Line endings to use when inserting a line break.
//    ///
//    /// The value only affects new line breaks inserted in the text view and changing this value does not change the line endings of the text in the text view. Defaults to Unix (LF).
//    ///
//    /// The TextView will only update the line endings when text is modified through an external event, such as when the user typing on the keyboard, when the user is replacing selected text, and when pasting text into the text view. In all other cases, you should make sure that the text provided to the text view uses the desired line endings. This includes when calling ``TextView/setState(_:addUndoAction:)``.
//    @Proxy(\TextView.typesetSettings.lineEndings.value)
//    public var lineEndings: LineEnding
//    /// The shape of the insertion point.
//    ///
//    /// Defaults to ``InsertionPointShape/verticalBar``.
//    @Proxy(\TextView.insertionPointShapeSubject.value)
//    public var insertionPointShape: InsertionPointShape
//    /// The color of the insertion point.
//    ///
//    /// This can be used to control the color of the caret.
//    @Proxy(\TextView.insertionPointBackgroundColorSubject.value)
//    public var insertionPointColor: NSColor
//    /// The color of the insertion point.
//    ///
//    /// This can be used to control the color of the caret.
//    @Proxy(\TextView.insertionPointTextColorSubject.value)
//    public var insertionPointForegroundColor: NSColor
//    /// The color of the insertion point.
//    ///
//    /// This can be used to control the color of the caret.
//    @Proxy(\TextView.insertionPointInvisibleCharacterColorSubject.value)
//    public var insertionPointInvisibleCharacterForegroundColor: NSColor
//    /// The color of the selection highlight.
//    ///
//    /// It is most common to set this to the same color as the color used for the insertion point.
//    @Proxy(\TextView.textSelectionLayouter.backgroundColor.value)
//    public var selectionHighlightColor: NSColor
//    /// The object that the document uses to support undo/redo operations.
//    override open var undoManager: UndoManager? {
//        _undoManager
//    }
//
//    let proxyScrollView: ProxyScrollView
//    let textViewDelegate: ErasedTextViewDelegate
//    let isFirstResponder: CurrentValueSubject<Bool, Never>
//    private let keyWindowObserver: KeyWindowObserver
//    private var boundsObserver: AnyCancellable?
//    private var windowDidResignKeyObserver: AnyCancellable?
//
//    let stringView: any StringView
//    let lineManager: LineManaging
//    let lineControllerStore: LineControllerStoring
//
//    let selectedRangeSubject: CurrentValueSubject<NSRange, Never>
//    let markedRangeSubject: CurrentValueSubject<NSRange?, Never>
//
//    let textContainer: TextContainer
//    let typesetSettings: TypesetSettings
//    let invisibleCharacterSettings: InvisibleCharacterSettings
//    let themeSettings: ThemeSettings
//
//    let _undoManager: UndoManager
//    let characterPairService: CharacterPairService
//    let indentationChecker: IndentationChecker
//
//    let languageMode: CurrentValueSubject<InternalLanguageMode, Never>
//    let languageModeSetter: LanguageModeSetter
//
//    let textSetter: TextSetter
//    let textViewStateSetter: TextViewStateSetter
//
//    let editorState: EditorState
//    let textReplacer: TextReplacer
////    let textInserter: TextInserter
////    let textDeleter: TextDeleter
//    let textShifter: TextShifter
//
//    let contentSizeService: ContentSizeService
//    private let estimatedLineHeight: EstimatedLineHeight
//    private let estimatedCharacterWidth: EstimatedCharacterWidth
//    private let widestLineTracker: WidestLineTracker
//
//    let locationNavigator: LocationNavigator
//    let locationRaycaster: LocationRaycaster
//    let selectionNavigator: SelectionNavigator
//    let lineMover: LineMover
//    let goToLineNavigator: GoToLineNavigator
//    let syntaxNodeRaycaster: SyntaxNodeRaycaster
//    let textLocationConverter: TextLocationConverter
//
//    let insertionPointLayouter: InsertionPointLayouter
//    let lineFragmentLayouter: LineFragmentLayouter
//    let textSelectionLayouter: TextSelectionLayouter
//    let lineSelectionLayouter: LineSelectionLayouter
//    let pageGuideLayouter: PageGuideLayouter
//
//    private let insertionPointShapeSubject: CurrentValueSubject<InsertionPointShape, Never>
//    private let insertionPointBackgroundColorSubject: CurrentValueSubject<MultiPlatformColor, Never>
//    private let insertionPointTextColorSubject: CurrentValueSubject<MultiPlatformColor, Never>
//    private let insertionPointInvisibleCharacterColorSubject: CurrentValueSubject<MultiPlatformColor, Never>
//
//    let viewportScroller: ViewportScroller
//    let automaticViewportScroller: AutomaticViewportScroller
//
//    let searchService: SearchService
//    let batchReplacer: BatchReplacer
//    let textPreviewFactory: TextPreviewFactory
//    let textFinder = NSTextFinder()
//    private let textFinderClient = TextFinderClient()
//
//    let highlightedRangeFragmentStore: HighlightedRangeFragmentStore
//    let highlightedRangeNavigator: HighlightedRangeNavigator
//
//    var scrollView: NSScrollView? {
//        guard let scrollView = enclosingScrollView, scrollView.documentView === self else {
//            return nil
//        }
//        return scrollView
//    }
//
//    private var shouldBeginEditing: Bool {
//        guard isEditable else {
//            return false
//        }
//        if let editorDelegate = editorDelegate {
//            return editorDelegate.textViewShouldBeginEditing(self)
//        } else {
//            return true
//        }
//    }
//    private var shouldEndEditing: Bool {
//        if let editorDelegate = editorDelegate {
//            return editorDelegate.textViewShouldEndEditing(self)
//        } else {
//            return true
//        }
//    }

    /// Create a new text view.
    public init() {
//        let compositionRoot = CompositionRoot()
//        _scrollView = compositionRoot.scrollView
//        textViewDelegate = compositionRoot.textViewDelegate
//        isFirstResponder = compositionRoot.isFirstResponder
//        keyWindowObserver = compositionRoot.keyWindowObserver
//
//        stringView = compositionRoot.stringView
//        lineManager = compositionRoot.lineManager
//        LineControllerStore = compositionRoot.LineControllerStore
//
//        selectedRangeSubject = compositionRoot.selectedRange
//        markedRangeSubject = compositionRoot.markedRange
//
//        textContainer = compositionRoot.textContainer
//        typesetSettings = compositionRoot.typesetSettings
//        invisibleCharacterSettings = compositionRoot.invisibleCharacterSettings
//        themeSettings = compositionRoot.themeSettings
//
//        _undoManager = compositionRoot.undoManager
//        characterPairService = compositionRoot.characterPairService
//        indentationChecker = compositionRoot.indentationChecker
//
//        languageMode = compositionRoot.languageMode
//        languageModeSetter = compositionRoot.languageModeSetter
//
//        textSetter = compositionRoot.textSetter
//        textViewStateSetter = compositionRoot.textViewStateSetter
//
//        editorState = compositionRoot.editorState
//        textReplacer = compositionRoot.textReplacer
//        textInserter = compositionRoot.textInserter
//        textDeleter = compositionRoot.textDeleter
//        textShifter = compositionRoot.textShifter
//
//        contentSizeService = compositionRoot.contentSizeService
//        estimatedLineHeight = compositionRoot.estimatedLineHeight
//        estimatedCharacterWidth = compositionRoot.estimatedCharacterWidth
//        widestLineTracker = compositionRoot.widestLineTracker
//
//        locationNavigator = compositionRoot.locationNavigator
//        locationRaycaster = compositionRoot.locationRaycaster
//        selectionNavigator = compositionRoot.selectionNavigator
//        lineMover = compositionRoot.lineMover
//        goToLineNavigator = compositionRoot.goToLineNavigator
//        syntaxNodeRaycaster = compositionRoot.syntaxNodeRaycaster
//        textLocationConverter = compositionRoot.textLocationConverter
//
//        insertionPointLayouter = compositionRoot.insertionPointLayouter
//        lineFragmentLayouter = compositionRoot.lineFragmentLayouter
//        textSelectionLayouter = compositionRoot.textSelectionLayouter
//        lineSelectionLayouter = compositionRoot.lineSelectionLayouter
//        pageGuideLayouter = compositionRoot.pageGuideLayouter
//
//        insertionPointShapeSubject = compositionRoot.insertionPointShape
//        insertionPointBackgroundColorSubject = compositionRoot.insertionPointBackgroundColor
//        insertionPointTextColorSubject = compositionRoot.insertionPointTextColor
//        insertionPointInvisibleCharacterColorSubject = compositionRoot.insertionPointInvisibleCharacterColor
//
//        viewportScroller = compositionRoot.viewportScroller
//        automaticViewportScroller = compositionRoot.automaticViewportScroller
//
//        searchService = compositionRoot.searchService
//        batchReplacer = compositionRoot.batchReplacer
//        textPreviewFactory = compositionRoot.textPreviewFactory
//
//        highlightedRangeFragmentStore = compositionRoot.highlightedRangeFragmentStore
//        highlightedRangeNavigator = compositionRoot.highlightedRangeNavigator
        super.init(frame: .zero)
//        compositionRoot.textView.value = WeakBox(self)
//        selectedRangeSubject.value = NSRange(location: 0, length: 0)
//        _scrollView.value = WeakBox(scrollView)
//        setupScrollViewBoundsDidChangeObserver()
//        setupMenu()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Create a scroll view with an instance of `TextView` assigned to the document view.
    public static func scrollableTextView() -> NSScrollView {
        let textView = TextView()
        textView.autoresizingMask = [.width, .height]
        let scrollView = NSScrollView()
        scrollView.contentView = FlippedClipView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
//        scrollView.hasVerticalScroller = true
//        scrollView.hasHorizontalScroller = true
        return scrollView
    }

    /// Informs the view that its superview has changed.
    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
//        _scrollView.value = WeakBox(scrollView)
        setupScrollViewBoundsDidChangeObserver()
        setupTextFinder()
    }

    /// Notifies the receiver that it's about to become first responder in its NSWindow.
    @discardableResult
    override open func becomeFirstResponder() -> Bool {
//        guard !isEditing && shouldBeginEditing else {
//            return false
//        }
        let didBecomeFirstResponder = super.becomeFirstResponder()
//        if didBecomeFirstResponder {
//            isFirstResponder.value = true
//            editorState.isEditing.value = true
//            editorDelegate?.textViewDidBeginEditing(self)
//        } else {
//            editorState.isEditing.value = false
//        }
        return didBecomeFirstResponder
    }

    /// Notifies the receiver that it's been asked to relinquish its status as first responder in its window.
    @discardableResult
    override open func resignFirstResponder() -> Bool {
//        guard isEditing && shouldEndEditing else {
//            return false
//        }
        let didResignFirstResponder = super.resignFirstResponder()
//        if didResignFirstResponder {
//            isFirstResponder.value = false
//            editorState.isEditing.value = false
//            editorDelegate?.textViewDidEndEditing(self)
//        }
        return didResignFirstResponder
    }

    /// Perform layout in concert with the constraint-based layout system.
    open override func layout() {
        super.layout()
        updateViewport()
//        caretLayouter.layoutIfNeeded()
//        lineFragmentLayouter.layoutIfNeeded()
//        lineSelectionLayouter.layoutIfNeeded()
//        contentSizeService.updateContentSizeIfNeeded()
    }

    /// Overridden by subclasses to define their default cursor rectangles.
    override public func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .iBeam)
    }

    /// Implemented to override the default action of enabling or disabling a specific menu item.
    /// - Parameter menuItem: An NSMenuItem object that represents the menu item.
    /// - Returns: `true` to enable menuItem, `false` to disable it.
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return false
//        if menuItem.action == #selector(copy(_:)) || menuItem.action == #selector(cut(_:)) {
//            return selectedRange().length > 0
//        } else if menuItem.action == #selector(paste(_:)) {
//            return NSPasteboard.general.canReadItem(withDataConformingToTypes: [UTType.plainText.identifier])
//        } else if menuItem.action == #selector(selectAll(_:)) {
//            return !text.isEmpty
//        } else if menuItem.action == #selector(undo(_:)) {
//            return undoManager?.canUndo ?? false
//        } else if menuItem.action == #selector(redo(_:)) {
//            return undoManager?.canRedo ?? false
//        } else {
//            return true
//        }
    }
}

// MARK: - Scrolling
private extension TextView {
    private func setupScrollViewBoundsDidChangeObserver() {
//        boundsObserver?.cancel()
//        boundsObserver = nil
//        guard let contentView = scrollView?.contentView else {
//            return
//        }
//        boundsObserver = NotificationCenter.default
//            .publisher(for: NSView.boundsDidChangeNotification, object: contentView)
//            .sink { [weak self] _ in
//                self?.updateViewport()
//            }
    }

    private func updateViewport() {
//        let viewport = textContainer.viewport
//        if let scrollView {
//            viewport.value = scrollView.documentVisibleRect
//        } else {
//            viewport.value = CGRect(origin: .zero, size: frame.size)
//        }
    }
}

// MARK: - Menu
private extension TextView {
    private func setupMenu() {
        menu = NSMenu()
        menu?.addItem(withTitle: L10n.Menu.ItemTitle.cut, action: #selector(cut(_:)), keyEquivalent: "")
        menu?.addItem(withTitle: L10n.Menu.ItemTitle.copy, action: #selector(copy(_:)), keyEquivalent: "")
        menu?.addItem(withTitle: L10n.Menu.ItemTitle.paste, action: #selector(paste(_:)), keyEquivalent: "")
    }
}

// MARK: - Find
private extension TextView {
    private func setupTextFinder() {
//        textFinderClient.textView = self
//        textFinder.client = textFinderClient
//        textFinder.findBarContainer = scrollView
    }
}
#endif
