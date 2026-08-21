import AppKit

@MainActor
final class FinderAddressBarController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private var panel: AddressBarPanel?
    private var textField: NSTextField?
    private var isDismissing = false

    private let onSubmit: (String) -> Bool
    private let onDismiss: () -> Void

    init(
        onSubmit: @escaping (String) -> Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
    }

    func show(path: String, anchorFrame: CGRect?) {
        dismiss(reactivateFinder: false)

        let targetScreen = screen(for: anchorFrame) ?? NSScreen.main ?? NSScreen.screens.first
        guard let targetScreen else {
            NSSound.beep()
            return
        }

        let usableFrame = targetScreen.visibleFrame
        let anchor = anchorFrame ?? usableFrame
        let width = min(max(anchor.width - 80, 420), 900)
        let height: CGFloat = 52
        let x = min(max(anchor.midX - width / 2, usableFrame.minX + 12), usableFrame.maxX - width - 12)
        let proposedY = anchor.maxY - height - 38
        let y = min(max(proposedY, usableFrame.minY + 12), usableFrame.maxY - height - 12)

        let panelFrame = CGRect(x: x, y: y, width: width, height: height)
        let panel = AddressBarPanel(
            contentRect: panelFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.delegate = self

        let effectView = NSVisualEffectView(frame: CGRect(origin: .zero, size: panelFrame.size))
        effectView.material = .popover
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 10
        effectView.layer?.masksToBounds = true

        let field = NSTextField(frame: CGRect(x: 12, y: 10, width: width - 24, height: 32))
        field.stringValue = path
        field.font = .systemFont(ofSize: 14)
        field.isEditable = true
        field.isSelectable = true
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.focusRingType = .default
        field.delegate = self
        field.autoresizingMask = [.width]

        effectView.addSubview(field)
        panel.contentView = effectView

        self.panel = panel
        self.textField = field

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            submit()
            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            dismiss(reactivateFinder: true)
            return true
        }

        return false
    }

    func windowDidResignKey(_ notification: Notification) {
        guard !isDismissing else { return }
        dismiss(reactivateFinder: false)
    }

    private func submit() {
        guard let value = textField?.stringValue else { return }

        if onSubmit(value) {
            dismiss(reactivateFinder: false)
        } else {
            NSSound.beep()
            textField?.currentEditor()?.selectAll(nil)
        }
    }

    private func dismiss(reactivateFinder: Bool) {
        guard panel != nil else {
            if reactivateFinder {
                onDismiss()
            }
            return
        }

        isDismissing = true
        panel?.orderOut(nil)
        panel?.delegate = nil
        panel = nil
        textField = nil
        isDismissing = false

        if reactivateFinder {
            onDismiss()
        }
    }

    private func screen(for frame: CGRect?) -> NSScreen? {
        guard let frame else { return nil }

        return NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        }
    }
}

private final class AddressBarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else { return 0 }
        return width * height
    }
}
