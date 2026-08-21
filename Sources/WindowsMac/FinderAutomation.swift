import AppKit
import Foundation
import WindowsMacCore

struct FinderWindowContext: Sendable {
    let path: String
    let windowID: Int32?
    let windowFrame: CGRect?
}

enum FinderAutomationFailure: Error, Sendable, Equatable {
    case automationDenied
    case noFilesystemPath
    case execution(String)
}

enum FinderNavigationResult: Sendable, Equatable {
    case success
    case invalidPath
    case notFolder
    case package
    case windowMissing
    case automationDenied
    case failure(String)
}

enum FinderAutomation {
    /// Initializes the AppleScript runtime from the main thread before any background
    /// automation work. Recent macOS/XProtect builds can otherwise stall the first
    /// NSAppleScript initialization when it happens on a worker thread.
    @MainActor
    static func prepareRuntime() {
        guard let script = NSAppleScript(source: "return 1") else { return }
        var error: NSDictionary?
        _ = script.executeAndReturnError(&error)
    }

    static func currentContext() -> Result<FinderWindowContext, FinderAutomationFailure> {
        let source = """
        tell application "Finder"
            if (count of Finder windows) is 0 then
                return {POSIX path of (path to home folder), 0, 0, 0, 0, 0}
            end if

            set targetWindow to front Finder window
            set windowID to id of targetWindow
            set b to bounds of targetWindow

            try
                set currentPath to POSIX path of (target of targetWindow as alias)
            on error
                set currentPath to ""
            end try

            return {currentPath, windowID, item 1 of b, item 2 of b, item 3 of b, item 4 of b}
        end tell
        """

        switch run(source) {
        case .failure(let failure):
            return .failure(failure)

        case .success(let descriptor):
            guard
                descriptor.numberOfItems >= 6,
                let pathDescriptor = descriptor.atIndex(1),
                let rawPath = pathDescriptor.stringValue,
                !rawPath.isEmpty,
                let normalizedPath = FinderPath.normalizedPath(from: rawPath),
                let idDescriptor = descriptor.atIndex(2),
                let leftDescriptor = descriptor.atIndex(3),
                let topDescriptor = descriptor.atIndex(4),
                let rightDescriptor = descriptor.atIndex(5),
                let bottomDescriptor = descriptor.atIndex(6)
            else {
                return .failure(.noFilesystemPath)
            }

            let rawWindowID = idDescriptor.int32Value
            let windowID = rawWindowID == 0 ? nil : rawWindowID

            var windowFrame: CGRect?
            if windowID != nil, let primaryScreen = NSScreen.screens.first {
                let left = CGFloat(leftDescriptor.int32Value)
                let top = CGFloat(topDescriptor.int32Value)
                let right = CGFloat(rightDescriptor.int32Value)
                let bottom = CGFloat(bottomDescriptor.int32Value)

                if right > left, bottom > top {
                    let accessibilityFrame = CGRect(
                        x: left,
                        y: top,
                        width: right - left,
                        height: bottom - top
                    )
                    windowFrame = CoordinateConverter.accessibilityToAppKit(
                        accessibilityFrame,
                        primaryScreenFrame: primaryScreen.frame
                    )
                }
            }

            return .success(
                FinderWindowContext(
                    path: normalizedPath,
                    windowID: windowID,
                    windowFrame: windowFrame
                )
            )
        }
    }

    static func openSelectedChildFolder() -> Result<Void, FinderAutomationFailure> {
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

        switch run(source) {
        case .success:
            return .success(())
        case .failure(let failure):
            return .failure(failure)
        }
    }

    /// Activates a stable Finder window slot. Finder's normal numeric indexes are
    /// front-to-back and change whenever a window is raised, so WindowsMac sorts the
    /// persistent Finder window IDs instead. Slots therefore remain stable while the
    /// corresponding windows stay open.
    static func activateWindow(index: Int) -> Result<Bool, FinderAutomationFailure> {
        guard index > 0 else { return .success(false) }

        let idsResult = run(
            """
            tell application "Finder"
                return id of every Finder window
            end tell
            """
        )

        let ids: [Int32]
        switch idsResult {
        case .failure(let failure):
            return .failure(failure)
        case .success(let descriptor):
            var values: [Int32] = []
            if descriptor.numberOfItems > 0 {
                for itemIndex in 1...descriptor.numberOfItems {
                    if let item = descriptor.atIndex(itemIndex) {
                        values.append(item.int32Value)
                    }
                }
            }
            ids = values.sorted()
        }

        guard ids.indices.contains(index - 1) else {
            return .success(false)
        }

        let targetID = ids[index - 1]
        let source = """
        tell application "Finder"
            set matchingWindows to every Finder window whose id is \(targetID)
            if (count of matchingWindows) is 0 then return false
            set index of item 1 of matchingWindows to 1
            activate
            return true
        end tell
        """

        switch run(source) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let descriptor):
            return .success(descriptor.booleanValue)
        }
    }

    static func navigate(to path: String, windowID: Int32?) -> FinderNavigationResult {
        let pathLiteral = AppleScriptString.expression(for: path)
        let windowIDValue = windowID ?? 0

        let source = """
        try
            set destinationAlias to (POSIX file \(pathLiteral) as alias)
            set destinationInfo to info for destinationAlias
        on error errorMessage number errorNumber
            return {"invalid-path", errorMessage, errorNumber}
        end try

        if folder of destinationInfo is false then
            return {"not-folder", "", 0}
        end if

        if package folder of destinationInfo is true then
            return {"package", "", 0}
        end if

        tell application "Finder"
            if \(windowIDValue) is 0 then
                open destinationAlias
            else
                set matchingWindows to every Finder window whose id is \(windowIDValue)
                if (count of matchingWindows) is 0 then
                    return {"window-missing", "", 0}
                end if
                set target of item 1 of matchingWindows to destinationAlias
            end if
        end tell

        return {"ok", "", 0}
        """

        switch run(source) {
        case .failure(.automationDenied):
            return .automationDenied

        case .failure(.noFilesystemPath):
            return .failure("Finder returned an unexpected path error.")

        case .failure(.execution(let message)):
            return .failure(message)

        case .success(let descriptor):
            guard
                descriptor.numberOfItems >= 1,
                let status = descriptor.atIndex(1)?.stringValue
            else {
                return .failure("Finder returned an unexpected navigation result.")
            }

            switch status {
            case "ok":
                return .success
            case "invalid-path":
                return .invalidPath
            case "not-folder":
                return .notFolder
            case "package":
                return .package
            case "window-missing":
                return .windowMissing
            default:
                let message = descriptor.atIndex(2)?.stringValue ?? status
                return .failure(message)
            }
        }
    }

    private static func run(
        _ source: String
    ) -> Result<NSAppleEventDescriptor, FinderAutomationFailure> {
        guard let script = NSAppleScript(source: source) else {
            return .failure(.execution("WindowsMac could not compile the Finder automation script."))
        }

        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)

        if let error {
            let number = (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue
            let message = (error[NSAppleScript.errorMessage] as? String)
                ?? "Finder automation failed."

            if number == -1743 {
                return .failure(.automationDenied)
            }

            return .failure(.execution(message))
        }

        return .success(descriptor)
    }
}
