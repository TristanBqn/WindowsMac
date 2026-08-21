import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "WindowsMac"

        let menu = NSMenu()
        let enabledItem = NSMenuItem(title: "Windows Mode", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
        enabledItem.state = .on
        enabledItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WindowsMac", action: #selector(quit), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
