import Testing
@testable import WindowsMacCore

@Test func appleScriptStringEncodesQuotesAndBackslashes() {
    #expect(
        AppleScriptString.expression(for: "/tmp/A \\\"quoted\\\" path")
            == "\"/tmp/A \\\\\\\"quoted\\\\\\\" path\""
    )
}

@Test func appleScriptStringEncodesControlCharactersAsExpressions() {
    #expect(
        AppleScriptString.expression(for: "one\ntwo\rthree\tfour")
            == "\"one\" & linefeed & \"two\" & return & \"three\" & tab & \"four\""
    )
}

@Test func appleScriptStringHandlesOnlyControlCharacter() {
    #expect(AppleScriptString.expression(for: "\n") == "linefeed")
}

@Test func appleScriptStringHandlesEmptyString() {
    #expect(AppleScriptString.expression(for: "") == "\"\"")
}
