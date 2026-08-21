import AppKit
import WindowsMacCore

@MainActor
final class FinderController {
    private var addressContext: FinderWindowContext?

    private lazy var addressBarController = FinderAddressBarController(
        onSubmit: { [weak self] rawPath, completion in
            guard let self else {
                completion(.cancelled)
                return
            }
            self.submitAddress(rawPath, completion: completion)
        },
        onDismiss: { [weak self] reactivateFinder in
            guard let self else { return }
            self.addressContext = nil
            if reactivateFinder {
                self.activateFinder()
            }
        }
    )

    func openSelectedChildFolder() {
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FinderAutomation.openSelectedChildFolder()
            }.value

            guard let self else { return }
            if case .failure(let failure) = result {
                self.handleAutomationFailure(failure)
            }
        }
    }

    func activateWindow(index: Int) {
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FinderAutomation.activateWindow(index: index)
            }.value

            guard let self else { return }
            switch result {
            case .success(let activated):
                if !activated {
                    NSSound.beep()
                }
            case .failure(let failure):
                self.handleAutomationFailure(failure)
            }
        }
    }

    func showAddressBar() {
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FinderAutomation.currentContext()
            }.value

            guard let self else { return }

            switch result {
            case .success(let context):
                self.addressContext = context
                self.addressBarController.show(
                    path: context.path,
                    anchorFrame: context.windowFrame
                )

            case .failure(let failure):
                self.handleAutomationFailure(failure)
            }
        }
    }

    private func submitAddress(
        _ rawPath: String,
        completion: @escaping (AddressBarSubmissionResult) -> Void
    ) {
        guard let path = FinderPath.normalizedPath(from: rawPath) else {
            completion(
                .failure("Enter an absolute POSIX path, ~/ path, or file:// URL.")
            )
            return
        }

        let windowID = addressContext?.windowID

        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FinderAutomation.navigate(to: path, windowID: windowID)
            }.value

            guard let self else {
                completion(.cancelled)
                return
            }

            switch result {
            case .success:
                completion(.success)

            case .invalidPath:
                completion(.failure("That path does not exist or is unavailable."))

            case .notFolder:
                completion(.failure("That path points to a file, not a folder."))

            case .package:
                completion(.failure("That path is a package, not a navigable folder."))

            case .windowMissing:
                completion(.failure("The original Finder window is no longer available."))

            case .automationDenied:
                completion(.cancelled)
                self.presentAutomationPermissionAlert()

            case .failure(let message):
                completion(.failure(message))
            }
        }
    }

    private func handleAutomationFailure(_ failure: FinderAutomationFailure) {
        switch failure {
        case .automationDenied:
            presentAutomationPermissionAlert()

        case .noFilesystemPath:
            presentError(
                title: "Finder location unavailable",
                message: "This Finder location does not expose a normal filesystem path."
            )

        case .execution(let message):
            presentError(
                title: "Finder automation failed",
                message: message
            )
        }
    }

    private func presentAutomationPermissionAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Finder permission required"
        alert.informativeText = "WindowsMac needs permission to control Finder so it can read the current path and navigate the Finder window you selected."
        alert.addButton(withTitle: "Open Automation Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(
               string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
           ) {
            NSWorkspace.shared.open(url)
        }
    }

    private func presentError(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func activateFinder() {
        let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first
        finder?.activate(options: [.activateIgnoringOtherApps])
    }
}
