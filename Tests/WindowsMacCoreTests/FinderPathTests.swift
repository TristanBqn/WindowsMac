import Foundation
import Testing
@testable import WindowsMacCore

@Test func finderPathAcceptsExistingDirectory() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    #expect(
        FinderPath.normalizedDirectoryPath(from: directory.path)
            == directory.standardizedFileURL.path
    )
}

@Test func finderPathAcceptsQuotedDirectory() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }

    #expect(
        FinderPath.normalizedDirectoryPath(from: "\"\(directory.path)\"")
            == directory.standardizedFileURL.path
    )
}

@Test func finderPathAcceptsFileURL() {
    let home = FileManager.default.homeDirectoryForCurrentUser

    #expect(
        FinderPath.normalizedDirectoryPath(from: home.absoluteString)
            == home.standardizedFileURL.path
    )
}

@Test func finderPathRejectsMissingDirectory() {
    let missing = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    #expect(FinderPath.normalizedDirectoryPath(from: missing.path) == nil)
}

@Test func finderPathRejectsRegularFile() throws {
    let file = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try Data().write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    #expect(FinderPath.normalizedDirectoryPath(from: file.path) == nil)
}
