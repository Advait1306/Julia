import AppKit
import SwiftUI

@main
struct NativeAPIKeyFieldTests {
    @MainActor static func main() {
        _ = NSApplication.shared
        // Hidden test window: no foreground activation or OS input events.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
                              styleMask: [.titled], backing: .buffered, defer: false)
        let fixture = String(repeating: "synthetic-key-", count: 50)
        var value = fixture
        var commits = 0
        let view = NativeAPIKeyField(text: Binding(get: { value }, set: { value = $0 })) { commits += 1 }
        let coordinator = view.makeCoordinator()
        let field = APIKeyTextField(frame: NSRect(x: 20, y: 20, width: 320, height: 22))
        field.delegate = coordinator
        field.stringValue = fixture
        window.contentView!.addSubview(field)
        let identity = ObjectIdentifier(field)

        precondition(field.cell is NSSecureTextFieldCell, "Idle content must use the native secure cell")
        precondition(window.makeFirstResponder(field), "The native control must accept focus")
        precondition(!(field.cell is NSSecureTextFieldCell), "Focus must reveal the native text cell")
        precondition(field.stringValue == fixture, "Focusing must preserve the key")
        precondition(ObjectIdentifier(field) == identity, "Reveal must preserve the control's identity")
        precondition(field.frame.width == 320, "Long content must remain bounded")

        guard let editor = field.currentEditor() as? NSTextView else {
            preconditionFailure("AppKit must provide the real text editor")
        }
        precondition(editor.string == fixture, "The native editor must contain the existing key")
        editor.setSelectedRange(NSRange(location: 5, length: 0))
        precondition(editor.selectedRange().location == 5, "Native cursor selection must work")
        precondition(window.makeFirstResponder(nil), "Editing must be able to end")
        precondition(field.cell is NSSecureTextFieldCell, "Ending editing must restore secure dots")
        precondition(value == fixture, "Ending editing must preserve the key")
        precondition(commits == 1, "Ending editing must commit exactly once")
        precondition(ObjectIdentifier(field) == identity, "Masking must preserve the control's identity")
        field.stopObserving()
        print("PASS: native field identity, reveal, cursor, bounded width, commit, and remasking")
    }
}
