import AppKit
import WindowsMacCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let karabiner = KarabinerController()
    private let windowManager = WindowManager()
    private let finderController = FinderController()
    private var receiver: UserCommandReceiver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        FinderAutomation.prepareRuntime()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "WindowsMac"

        let menu = NSMenu()
        let enabledItem = NSMenuItem(
            title: "Windows Mode",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        enabledItem.state = karabiner.setEnabled(true) ? .on : .off
        enabledItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit WindowsMac",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item

        startCommandReceiver()
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        let shouldEnable = sender.state != .on
        if karabiner.setEnabled(shouldEnable) {
            sender.state = shouldEnable ? .on : .off
        }
    }

    @objc private func quit() {
        _ = karabiner.setEnabled(false)
        Task {
            await receiver?.stop()
            NSApp.terminate(nil)
        }
    }

    private func startCommandReceiver() {
        let receiver = UserCommandReceiver { [weak self] data in
            Task { @MainActor in
                self?.handleCommand(data)
            }
        }
        self.receiver = receiver

        Task {
            do {
                try await receiver.start()
            } catch {
                NSLog("WindowsMac command receiver failed to start: \(error)")
            }
        }
    }

    private func handleCommand(_ data: Data) {
        do {
            let command = try JSONDecoder().decode(WindowsMacCommand.self, from: data)
            switch command.command {
            case .snap:
                guard let direction = command.direction else { return }
                windowManager.snap(direction)
            case .finderOpenChild:
                finderController.openSelectedChildFolder()
            case .finderAddressBar:
                finderController.showAddressBar()
            }
        } catch {
            NSLog("WindowsMac received invalid command: \(error)")
        }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
