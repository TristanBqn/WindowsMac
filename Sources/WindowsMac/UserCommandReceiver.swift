import Darwin
import Foundation

enum UserCommandReceiverError: Error {
    case alreadyRunning
    case socketCreationFailed(Int32)
    case invalidSocketPath
    case bindFailed(Int32)
}

actor UserCommandReceiver {
    typealias Handler = @Sendable (Data) -> Void

    private let socketPath: String
    private let handler: Handler
    private var fileDescriptor: Int32 = -1
    private var receiveTask: Task<Void, Never>?

    init(
        socketPath: String = UserCommandReceiver.defaultSocketPath(),
        handler: @escaping Handler
    ) {
        self.socketPath = socketPath
        self.handler = handler
    }

    static func defaultSocketPath() -> String {
        "/Library/Application Support/org.pqrs/tmp/user/\(geteuid())/user_command_receiver.sock"
    }

    func start() throws {
        guard receiveTask == nil, fileDescriptor < 0 else {
            throw UserCommandReceiverError.alreadyRunning
        }

        let descriptor = socket(AF_UNIX, SOCK_DGRAM, 0)
        guard descriptor >= 0 else {
            throw UserCommandReceiverError.socketCreationFailed(errno)
        }

        do {
            try bindSocket(descriptor, to: socketPath)
        } catch {
            close(descriptor)
            throw error
        }

        fileDescriptor = descriptor
        let handler = self.handler

        receiveTask = Task.detached(priority: .userInitiated) {
            var buffer = [UInt8](repeating: 0, count: 32 * 1024)

            while !Task.isCancelled {
                var pollDescriptor = pollfd(
                    fd: descriptor,
                    events: Int16(POLLIN),
                    revents: 0
                )

                let pollResult = poll(&pollDescriptor, 1, 500)
                if pollResult <= 0 {
                    continue
                }

                let count = recv(descriptor, &buffer, buffer.count, 0)
                guard count > 0 else {
                    continue
                }

                var end = count
                while end > 0 && (buffer[end - 1] == 0x0A || buffer[end - 1] == 0x0D) {
                    end -= 1
                }
                guard end > 0 else { continue }

                handler(Data(buffer[0..<end]))
            }
        }
    }

    func stop() {
        receiveTask?.cancel()
        receiveTask = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }

        socketPath.withCString { _ = unlink($0) }
    }

    private func bindSocket(_ descriptor: Int32, to path: String) throws {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)

        let pathBytes = path.utf8CString
        let maximumLength = MemoryLayout.size(ofValue: address.sun_path)
        guard pathBytes.count <= maximumLength else {
            throw UserCommandReceiverError.invalidSocketPath
        }

        path.withCString { source in
            withUnsafeMutablePointer(to: &address.sun_path) { pointer in
                pointer.withMemoryRebound(to: CChar.self, capacity: maximumLength) { destination in
                    strncpy(destination, source, maximumLength - 1)
                    destination[maximumLength - 1] = 0
                }
            }
        }

        path.withCString { _ = unlink($0) }

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(
                    descriptor,
                    $0,
                    socklen_t(MemoryLayout<sockaddr_un>.size)
                )
            }
        }

        guard result == 0 else {
            throw UserCommandReceiverError.bindFailed(errno)
        }
    }
}
