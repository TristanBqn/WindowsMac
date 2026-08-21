import AppKit

@MainActor
final class FinderController {
    func openSelectedChildFolder() {
        let source = """
        tell application "Finder"
            if (count of selection) is not 1 then return
            set selectedItem to item 1 of selection
            if class of selectedItem is folder then
                if (count of Finder windows) is 0 then
                    open selectedItem
                else
                    set target of front Finder window to selectedItem
                end if
            end if
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            NSLog("WindowsMac Finder navigation failed: \(error)")
        }
    }

    func showAddressBar() {
        // Reserved until the address bar panel is implemented.
        NSSound.beep()
    }
}
