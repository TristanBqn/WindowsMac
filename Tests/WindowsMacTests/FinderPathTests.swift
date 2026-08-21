import Foundation
import XCTest
@testable import WindowsMacCore

final class FinderPathTests: XCTestCase {
    func testNormalizesAbsolutePOSIXPath() {
        XCTAssertEqual(FinderPath.normalizedPath(from: "/tmp/WindowsMac"), URL(fileURLWithPath: "/tmp/WindowsMac").standardizedFileURL.path)
    }

    func testDoesNotRequireDestinationToExist() {
        let missing = "/tmp/windowsmac-\(UUID().uuidString)/missing"
        XCTAssertEqual(FinderPath.normalizedPath(from: missing), URL(fileURLWithPath: missing).standardizedFileURL.path)
    }

    func testExpandsTilde() {
        let expected = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").standardizedFileURL.path
        XCTAssertEqual(FinderPath.normalizedPath(from: "~/Documents"), expected)
    }

    func testAcceptsDoubleQuotedPath() {
        XCTAssertEqual(FinderPath.normalizedPath(from: "\"/tmp/Some Folder\""), "/tmp/Some Folder")
    }

    func testAcceptsSingleQuotedPath() {
        XCTAssertEqual(FinderPath.normalizedPath(from: "'/tmp/Some Folder'"), "/tmp/Some Folder")
    }

    func testAcceptsPercentEncodedFileURL() {
        let url = URL(fileURLWithPath: "/tmp/Windows Mac/éxample #1")
        XCTAssertEqual(FinderPath.normalizedPath(from: url.absoluteString), url.standardizedFileURL.path)
    }

    func testPreservesUnicodeAndSymbols() {
        let path = "/tmp/Projet été & R&D #1"
        XCTAssertEqual(FinderPath.normalizedPath(from: path), URL(fileURLWithPath: path).standardizedFileURL.path)
    }

    func testStandardizesParentComponents() {
        XCTAssertEqual(FinderPath.normalizedPath(from: "/tmp/one/../two"), "/tmp/two")
    }

    func testRejectsRelativePath() {
        XCTAssertNil(FinderPath.normalizedPath(from: "Documents/Client"))
    }

    func testRejectsEmptyInput() {
        XCTAssertNil(FinderPath.normalizedPath(from: "   "))
        XCTAssertNil(FinderPath.normalizedPath(from: "\"\""))
    }
}
