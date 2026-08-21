import Foundation

public enum FinderPath {
    /// Normalizes text entered in the Finder address bar without touching the filesystem.
    ///
    /// Supported inputs:
    /// - absolute POSIX paths
    /// - `~`-prefixed paths
    /// - quoted paths
    /// - `file://` URLs
    ///
    /// Existence and folder/package validation are deliberately delegated to Finder/AppleScript
    /// so the UI does not synchronously probe network, cloud or privacy-protected locations.
    public static func normalizedPath(from input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if value.count >= 2,
           (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
           (value.hasPrefix("'") && value.hasSuffix("'")) {
            value.removeFirst()
            value.removeLast()
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !value.isEmpty else { return nil }

        if value.lowercased().hasPrefix("file://") {
            guard
                let fileURL = URL(string: value),
                fileURL.isFileURL
            else {
                return nil
            }

            return fileURL.standardizedFileURL.path
        }

        let expanded = NSString(string: value).expandingTildeInPath
        guard expanded.hasPrefix("/") else {
            return nil
        }

        return URL(fileURLWithPath: expanded).standardizedFileURL.path
    }
}
