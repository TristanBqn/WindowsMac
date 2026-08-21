import CoreGraphics

public enum WindowState: String, CaseIterable, Sendable {
    case normal
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

public enum WindowGeometry {
    public static func frame(for state: WindowState, in visibleFrame: CGRect) -> CGRect {
        let x = visibleFrame.minX
        let y = visibleFrame.minY
        let width = visibleFrame.width
        let height = visibleFrame.height
        let halfWidth = width / 2
        let halfHeight = height / 2

        switch state {
        case .normal:
            return visibleFrame
        case .maximized:
            return visibleFrame
        case .leftHalf:
            return CGRect(x: x, y: y, width: halfWidth, height: height)
        case .rightHalf:
            return CGRect(x: x + halfWidth, y: y, width: halfWidth, height: height)
        case .topHalf:
            return CGRect(x: x, y: y + halfHeight, width: width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: x, y: y, width: width, height: halfHeight)
        case .topLeft:
            return CGRect(x: x, y: y + halfHeight, width: halfWidth, height: halfHeight)
        case .topRight:
            return CGRect(x: x + halfWidth, y: y + halfHeight, width: halfWidth, height: halfHeight)
        case .bottomLeft:
            return CGRect(x: x, y: y, width: halfWidth, height: halfHeight)
        case .bottomRight:
            return CGRect(x: x + halfWidth, y: y, width: halfWidth, height: halfHeight)
        }
    }

    public static func nextState(from current: WindowState, direction: Direction) -> WindowState {
        switch (current, direction) {
        case (.leftHalf, .up): return .topLeft
        case (.leftHalf, .down): return .bottomLeft
        case (.rightHalf, .up): return .topRight
        case (.rightHalf, .down): return .bottomRight
        case (.topHalf, .up): return .maximized
        case (_, .left): return .leftHalf
        case (_, .right): return .rightHalf
        case (_, .up): return .topHalf
        case (_, .down): return .bottomHalf
        }
    }
}

public enum Direction: Sendable {
    case left
    case right
    case up
    case down
}
