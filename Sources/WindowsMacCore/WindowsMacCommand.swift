import Foundation

public struct WindowsMacCommand: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Sendable {
        case snap
        case finderOpenChild
        case finderAddressBar
    }

    public let command: Action
    public let direction: Direction?

    public init(command: Action, direction: Direction? = nil) {
        self.command = command
        self.direction = direction
    }
}
