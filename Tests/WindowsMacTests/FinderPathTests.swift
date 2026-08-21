import Foundation
import Testing
@testable import WindowsMacCore

@Test func finderPathNormalizesAbsolutePOSIXPath() {
    #expect(
        FinderPath.normalizedPath(from: "/tmp/WindowsMac")
            == URL(fileURLWithPath: "/tmp/WindowsMac").standardizedFileURL.path
    )
}

@Test func finderPathDoesNotRequireTheDestinationToExist() {
    let missing = "/tmp/windowsmac-\(UUID().uuidString)/missing"

    #expect(
        FinderPath.normalizedPath(from: missing)
            == URL(fileURLWithPath: missing).standardizedFileURL.path
    )
}

@Test func finderPathExpandsTilde() {
    let expected = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents")
        .standardizedFileURL.path

    #expect(FinderPath.normalizedPath(from: "~/Documents") == expected)
}

@Test func finderPathAcceptsDoubleQuotedPath() {
    #expect(
        FinderPath.normalizedPath(from: "\"/tmp/Some Folder\"")
            == "/tmp/Some Folder"
    )
}

@Test func finderPathAcceptsSingleQuotedPath() {
    #expect(
        FinderPath.normalizedPath(from: "'/tmp/Some Folder'")
            == "/tmp/Some Folder"
    )
}

@Test func finderPathAcceptsPercentEncodedFileURL() {
    let url = URL(fileURLWithPath: "/tmp/Windows Mac/éxample #1")

    #expect(
        FinderPath.normalizedPath(from: url.absoluteString)
            == url.standardizedFileURL.path
    )
}

@Test func finderPathPreservesUnicodeAndSymbols() {
    let path = "/tmp/Projet été & R&D #1"

    #expect(
        FinderPath.normalizedPath(from: path)
            == URL(fileURLWithPath: path).standardizedFileURL.path
    )
}

@Test func finderPathStandardizesParentComponents() {
    #expect(
        FinderPath.normalizedPath(from: "/tmp/one/../two")
            == "/tmp/two"
    )
}

@Test func finderPathRejectsRelativePath() {
    #expect(FinderPath.normalizedPath(from: "Documents/Client") == nil)
}

@Test func finderPathRejectsEmptyInput() {
    #expect(FinderPath.normalizedPath(from: "   ") == nil)
    #expect(FinderPath.normalizedPath(from: "\"\"") == nil)
}
