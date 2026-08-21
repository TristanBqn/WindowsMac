import CoreGraphics

public enum WindowSnapState: String, CaseIterable, Sendable {
    case maximized
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

public enum Direction: String, Codable, Sendable {
    case left
    case right
    case up
    case down
}

public enum WindowGeometry {
    public static func frame(for state: WindowSnapState, in visibleFrame: CGRect) -> CGRect {
        let halfWidth = visibleFrame.width / 2
        let halfHeight = visibleFrame.height / 2

        switch state {
        case .maximized:
            return visibleFrame
        case .leftHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .rightHalf:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height)
        case .topHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: visibleFrame.width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfHeight)
        case .topLeft:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .topRight:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY + halfHeight, width: halfWidth, height: halfHeight)
        case .bottomLeft:
            return CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        case .bottomRight:
            return CGRect(x: visibleFrame.minX + halfWidth, y: visibleFrame.minY, width: halfWidth, height: halfHeight)
        }
    }

    public static func matchingState(
        for frame: CGRect,
        in visibleFrame: CGRect,
        tolerance: CGFloat = 8
    ) -> WindowSnapState? {
        WindowSnapState.allCases.first {
            approximatelyEqual(frame, self.frame(for: $0, in: visibleFrame), tolerance: tolerance)
        }
    }

    public static func nextState(
        from current: WindowSnapState?,
        direction: Direction
    ) -> WindowSnapState {
        switch (current, direction) {
        case (.leftHalf, .up): return .topLeft
        case (.leftHalf, .down): return .bottomLeft
        case (.rightHalf, .up): return .topRight
        case (.rightHalf, .down): return .bottomRight
        case (.topHalf, .up): return .maximized
        case (.topLeft, .right): return .topRight
        case (.topRight, .left): return .topLeft
        case (.bottomLeft, .right): return .bottomRight
        case (.bottomRight, .left): return .bottomLeft
        case (_, .left): return .leftHalf
        case (_, .right): return .rightHalf
        case (_, .up): return .topHalf
        case (_, .down): return .bottomHalf
        }
    }

    private static func approximatelyEqual(
        _ lhs: CGRect,
        _ rhs: CGRect,
        tolerance: CGFloat
    ) -> Bool {
        abs(lhs.minX - rhs.minX) <= tolerance
            && abs(lhs.minY - rhs.minY) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }
}
