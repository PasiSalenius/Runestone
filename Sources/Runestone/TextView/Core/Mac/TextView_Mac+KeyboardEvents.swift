#if os(macOS)
import AppKit

public extension TextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags
        if flags.contains(.command),
           !flags.contains(.control),
           !flags.contains(.option),
           event.charactersIgnoringModifiers == "/" {
            toggleCommentOnSelectedLines()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    /// Informs the receiver that the user has pressed a key.
    /// - Parameter event: An object encapsulating information about the key-down event.
    override func keyDown(with event: NSEvent) {
        if editorDelegate?.textView(self, shouldHandleKeyDown: event) == true {
            return
        }
        NSCursor.setHiddenUntilMouseMoves(true)
        let didInputContextHandleEvent = inputContext?.handleEvent(event) ?? false
        if !didInputContextHandleEvent {
            super.keyDown(with: event)
        }
    }
}
#endif
