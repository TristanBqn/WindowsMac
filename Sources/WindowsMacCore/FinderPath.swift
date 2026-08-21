import Foundation

public enum FinderPath {
    /// Converts text entered in the Finder address bar into an existing directory path.
    /// Supports POSIX paths, `~` expansion and `file://` URLs.
    public static func normalizedDirectoryPath(from input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if value.count >= 2,
           (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
           (value.hasPrefix("'") && value.hasSuffix("'")) {
            value.removeFirst()
            value.removeLast()
        }

        let url: URL
        if value.lowercased().hasPrefix("file://") {
            guard let fileURL = URL(string: value), fileURL.isFileURL else {
                return nil
            }
            url = fileURL
        } else {
            let expanded = NSString(string: value).expandingTildeInPath
            url = URL(fileURLWithPath: expanded)
        }

        let standardized = url.standardizedFileURL
        var isDirectory = ObjCBool(false)
        guard
            FileManager.default.fileExists(
                atPath: standardized.path,
                isDirectory: &isDirectory
            ),
            isDirectory.boolValue
        else {
            return nil
        }

        return standardized.path
    }
}
