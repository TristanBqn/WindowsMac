import Foundation

struct KarabinerController {
    private let cliPath =
        "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = [
            "--silent",
            "--set-variables",
            "{\"windowsmac_enabled\":\(enabled ? 1 : 0)}"
        ]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            NSLog("WindowsMac could not update Karabiner state: \(error)")
            return false
        }
    }
}
