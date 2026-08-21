public enum AppleScriptString {
    /// Returns an AppleScript expression representing `value` without injecting raw text
    /// into a single quoted literal. Control characters are emitted as AppleScript constants.
    public static func expression(for value: String) -> String {
        var expressions: [String] = []
        var current = ""

        func appendCurrent() {
            guard !current.isEmpty else { return }
            expressions.append("\"\(current)\"")
            current.removeAll(keepingCapacity: true)
        }

        for character in value {
            switch character {
            case "\\":
                current += "\\\\"
            case "\"":
                current += "\\\""
            case "\n":
                appendCurrent()
                expressions.append("linefeed")
            case "\r":
                appendCurrent()
                expressions.append("return")
            case "\t":
                appendCurrent()
                expressions.append("tab")
            default:
                current.append(character)
            }
        }

        appendCurrent()
        return expressions.isEmpty ? "\"\"" : expressions.joined(separator: " & ")
    }
}
