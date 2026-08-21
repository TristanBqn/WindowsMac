import XCTest
@testable import WindowsMacCore

final class AppleScriptStringTests: XCTestCase {
    func testEncodesQuotesAndBackslashes() {
        XCTAssertEqual(
            AppleScriptString.expression(for: "/tmp/A \\\"quoted\\\" path"),
            "\"/tmp/A \\\\\\\"quoted\\\\\\\" path\""
        )
    }

    func testEncodesControlCharactersAsExpressions() {
        XCTAssertEqual(
            AppleScriptString.expression(for: "one\ntwo\rthree\tfour"),
            "\"one\" & linefeed & \"two\" & return & \"three\" & tab & \"four\""
        )
    }

    func testHandlesOnlyControlCharacter() {
        XCTAssertEqual(AppleScriptString.expression(for: "\n"), "linefeed")
    }

    func testHandlesEmptyString() {
        XCTAssertEqual(AppleScriptString.expression(for: ""), "\"\"")
    }
}
