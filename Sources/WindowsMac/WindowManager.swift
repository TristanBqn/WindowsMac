import AppKit
import ApplicationServices
import WindowsMacCore

@MainActor
final class WindowManager {
    private var restoreFrames: [CFHashCode: CGRect] = [:]

    func snap(_ direction: Direction) {
        guard AXIsProcessTrusted() else {
            NSLog("WindowsMac requires Accessibility permission for window snapping.")
            return
        }

        guard
            let window = focusedWindow(),
            !isNativeFullscreen(window),
            isResizable(window),
            let axFrame = frame(of: window),
            let primaryScreen = NSScreen.screens.first
        else {
            return
        }

        let appKitFrame = CoordinateConverter.accessibilityToAppKit(
            axFrame,
            primaryScreenFrame: primaryScreen.frame
        )

        guard let screen = screen(containing: appKitFrame) else {
            return
        }

        let currentState = WindowGeometry.matchingState(
            for: appKitFrame,
            in: screen.visibleFrame
        )
        let key = CFHash(window)

        if currentState == nil {
            restoreFrames[key] = appKitFrame
        }

        let targetState = WindowGeometry.nextState(
            from: currentState,
            direction: direction
        )
        let targetAppKitFrame = WindowGeometry.frame(
            for: targetState,
            in: screen.visibleFrame
        )
        let targetAXFrame = CoordinateConverter.appKitToAccessibility(
            targetAppKitFrame,
            primaryScreenFrame: primaryScreen.frame
        )

        setFrame(targetAXFrame, of: window)
    }

    private func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?

        guard
            AXUIElementCopyAttributeValue(
                appElement,
                kAXFocusedWindowAttribute as CFString,
                &value
            ) == .success,
            let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }

        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
            let positionValue,
            let sizeValue,
            CFGetTypeID(positionValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }

        let positionAXValue = unsafeBitCast(positionValue, to: AXValue.self)
        let sizeAXValue = unsafeBitCast(sizeValue, to: AXValue.self)

        var position = CGPoint.zero
        var size = CGSize.zero

        guard
            AXValueGetValue(positionAXValue, .cgPoint, &position),
            AXValueGetValue(sizeAXValue, .cgSize, &size)
        else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    private func setFrame(_ frame: CGRect, of window: AXUIElement) {
        var position = frame.origin
        var size = frame.size

        guard
            let positionValue = AXValueCreate(.cgPoint, &position),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else {
            return
        }

        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        _ = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    private func isResizable(_ window: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(
            window,
            kAXSizeAttribute as CFString,
            &settable
        ) == .success && settable.boolValue
    }

    private func isNativeFullscreen(_ window: AXUIElement) -> Bool {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(
                window,
                "AXFullScreen" as CFString,
                &value
            ) == .success
        else {
            return false
        }

        return (value as? Bool) == true
    }

    private func screen(containing frame: CGRect) -> NSScreen? {
        NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        }
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else { return 0 }
        return width * height
    }
}
