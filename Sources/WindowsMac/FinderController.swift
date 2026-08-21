import AppKit
import WindowsMacCore

@MainActor
final class FinderController {
    private struct Context {
        let path: String
        let windowFrame: CGRect?
    }

    private lazy var addressBarController = FinderAddressBarController(
        onSubmit: { [weak self] rawPath in
            self?.navigate(to: rawPath) ?? false
        },
        onDismiss: { [weak self] in
            self?.activateFinder()
        }
    )

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

        execute(source, logPrefix: "Finder navigation")
    }

    func showAddressBar() {
        guard let context = currentContext() else {
            NSSound.beep()
            return
        }

        addressBarController.show(
            path: context.path,
            anchorFrame: context.windowFrame
        )
    }

    private func currentContext() -> Context? {
        let source = """
        tell application "Finder"
            if (count of Finder windows) is 0 then
                return POSIX path of (path to home folder)
            end if

            try
                set currentPath to POSIX path of (target of front Finder window as alias)
            on error
                return ""
            end try

            set b to bounds of front Finder window
            return currentPath & linefeed & ¬
                ((item 1 of b) as text) & "," & ¬
                ((item 2 of b) as text) & "," & ¬
                ((item 3 of b) as text) & "," & ¬
                ((item 4 of b) as text)
        end tell
        """

        var error: NSDictionary?
        guard
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error),
            error == nil,
            let value = result.stringValue,
            !value.isEmpty
        else {
            if let error {
                NSLog("WindowsMac Finder path lookup failed: \(error)")
            }
            return nil
        }

        let lines = value.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard let first = lines.first else { return nil }

        let path = String(first)
        var appKitWindowFrame: CGRect?

        if lines.count == 2 {
            let values = lines[1].split(separator: ",").compactMap { Double($0) }
            if values.count == 4,
               let primaryScreen = NSScreen.screens.first {
                let axFrame = CGRect(
                    x: values[0],
                    y: values[1],
                    width: values[2] - values[0],
                    height: values[3] - values[1]
                )
                appKitWindowFrame = CoordinateConverter.accessibilityToAppKit(
                    axFrame,
                    primaryScreenFrame: primaryScreen.frame
                )
            }
        }

        return Context(path: path, windowFrame: appKitWindowFrame)
    }

    private func navigate(to rawPath: String) -> Bool {
        guard let path = FinderPath.normalizedDirectoryPath(from: rawPath) else {
            return false
        }

        let escapedPath = appleScriptEscaped(path)
        let source = """
        tell application "Finder"
            try
                set destinationFolder to (POSIX file "\(escapedPath)" as alias)
                if (count of Finder windows) is 0 then
                    open destinationFolder
                else
                    set target of front Finder window to destinationFolder
                end if
                activate
                return "ok"
            on error errorMessage
                return "error:" & errorMessage
            end try
        end tell
        """

        var error: NSDictionary?
        guard
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error),
            error == nil,
            result.stringValue == "ok"
        else {
            if let error {
                NSLog("WindowsMac Finder address navigation failed: \(error)")
            }
            return false
        }

        return true
    }

    private func activateFinder() {
        execute(
            "tell application \"Finder\" to activate",
            logPrefix: "Finder activation"
        )
    }

    private func execute(_ source: String, logPrefix: String) {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            NSLog("WindowsMac \(logPrefix) failed: \(error)")
        }
    }

    private func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
