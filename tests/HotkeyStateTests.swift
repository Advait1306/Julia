import AppKit
import Carbon.HIToolbox

@main
struct HotkeyStateTests {
    @MainActor static func main() {
        let hotkeys = HotkeyManager()
        let command = UInt64(NSEvent.ModifierFlags.command.rawValue)
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_Command), flags: command | 0x08)
        precondition(!hotkeys.rightCommandDown, "Left Command must not light up the indicator")
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_RightCommand), flags: command | 0x18)
        precondition(hotkeys.rightCommandDown, "Right Command must light up the indicator")
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_Command), flags: command | 0x10)
        precondition(hotkeys.rightCommandDown, "Releasing left Command must not clear right Command")
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_RightCommand), flags: 0)
        precondition(!hotkeys.rightCommandDown, "Releasing right Command must reset the indicator")
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_RightCommand), flags: command | 0x10)
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_Command), flags: command | 0x18)
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_RightCommand), flags: command | 0x08)
        precondition(!hotkeys.rightCommandDown, "Left Command staying held must not keep the indicator active")
        hotkeys.handle(type: .flagsChanged, keyCode: UInt16(kVK_RightCommand), flags: command | 0x18)
        hotkeys.stop()
        precondition(!hotkeys.rightCommandDown, "Closing the page must reset held-key state")
        print("PASS: right Command indicator distinguishes left/right press, release, and teardown")
    }
}
