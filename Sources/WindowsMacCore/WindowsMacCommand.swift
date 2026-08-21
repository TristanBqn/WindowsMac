import Foundation

public struct WindowsMacCommand: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Sendable {
        case snap
        case finderOpenChild
        case finderAddressBar
        case finderActivateWindow
    }

    public let command: Action
    public let direction: Direction?
    public let index: Int?

    public init(
        command: Action,
        direction: Direction? = nil,
        index: Int? = nil
    ) {
        self.command = command
        self.direction = direction
        self.index = index
    }
}
