import AppKit

enum AddressBarSubmissionResult {
    case success
    case failure(String)
    case cancelled
}

@MainActor
final class FinderAddressBarController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private var panel: AddressBarPanel?
    private var textField: NSTextField?
    private var errorLabel: NSTextField?
    private var isDismissing = false
    private var isSubmitting = false

    private let onSubmit: (String, @escaping (AddressBarSubmissionResult) -> Void) -> Void
    private let onDismiss: (Bool) -> Void

    init(
        onSubmit: @escaping (String, @escaping (AddressBarSubmissionResult) -> Void) -> Void,
        onDismiss: @escaping (Bool) -> Void
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
        let height: CGFloat = 76
        let x = min(
            max(anchor.midX - width / 2, usableFrame.minX + 12),
            usableFrame.maxX - width - 12
        )
        let proposedY = anchor.maxY - height - 38
        let y = min(
            max(proposedY, usableFrame.minY + 12),
            usableFrame.maxY - height - 12
        )

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
        panel.collectionBehavior = [.transient, .fullScreenAuxiliary, .canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        panel.delegate = self

        let effectView = NSVisualEffectView(
            frame: CGRect(origin: .zero, size: panelFrame.size)
        )
        effectView.material = .popover
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 10
        effectView.layer?.masksToBounds = true

        let field = NSTextField(
            frame: CGRect(x: 12, y: 32, width: width - 24, height: 32)
        )
        field.stringValue = path
        field.font = .systemFont(ofSize: 14)
        field.isEditable = true
        field.isSelectable = true
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.focusRingType = .default
        field.delegate = self
        field.autoresizingMask = [.width]

        let errorLabel = NSTextField(
            frame: CGRect(x: 14, y: 8, width: width - 28, height: 17)
        )
        errorLabel.isEditable = false
        errorLabel.isSelectable = false
        errorLabel.isBezeled = false
        errorLabel.drawsBackground = false
        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = .systemRed
        errorLabel.lineBreakMode = .byTruncatingTail
        errorLabel.isHidden = true
        errorLabel.autoresizingMask = [.width]

        effectView.addSubview(field)
        effectView.addSubview(errorLabel)
        panel.contentView = effectView
        panel.addressField = field

        self.panel = panel
        self.textField = field
        self.errorLabel = errorLabel
        self.isSubmitting = false

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
        guard
            !isSubmitting,
            let field = textField
        else {
            return
        }

        // NSTextField.stringValue can lag behind the active field editor while the
        // user is still typing or has just pasted. The field editor is authoritative.
        let submittedText = field.currentEditor()?.string ?? field.stringValue

        isSubmitting = true
        field.isEnabled = false
        errorLabel?.isHidden = true

        onSubmit(submittedText) { [weak self] result in
            self?.finishSubmission(result)
        }
    }

    private func finishSubmission(_ result: AddressBarSubmissionResult) {
        guard panel != nil else { return }

        isSubmitting = false

        switch result {
        case .success:
            dismiss(reactivateFinder: true)

        case .cancelled:
            dismiss(reactivateFinder: false)

        case .failure(let message):
            textField?.isEnabled = true
            errorLabel?.stringValue = message
            errorLabel?.isHidden = false
            panel?.makeFirstResponder(textField)
            textField?.currentEditor()?.selectAll(nil)
        }
    }

    private func dismiss(reactivateFinder: Bool) {
        guard panel != nil else { return }

        isDismissing = true
        panel?.orderOut(nil)
        panel?.delegate = nil
        panel = nil
        textField = nil
        errorLabel = nil
        isSubmitting = false
        isDismissing = false

        onDismiss(reactivateFinder)
    }

    private func screen(for frame: CGRect?) -> NSScreen? {
        guard let frame else { return nil }

        return NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        }
    }
}

private final class AddressBarPanel: NSPanel {
    weak var addressField: NSTextField?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Handle Windows-style editing shortcuts inside WindowsMac itself.
    /// Karabiner may deliver the original Control chord or an already-remapped
    /// Command/Option chord, so the panel accepts the relevant forms directly.
    override func sendEvent(_ event: NSEvent) {
        if handleWindowsEditingShortcut(event) {
            return
        }

        super.sendEvent(event)
    }

    private func handleWindowsEditingShortcut(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return false }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let editor = addressField?.currentEditor() as? NSTextView else {
            return false
        }

        if flags.contains(.control) || flags.contains(.command) {
            if let key = event.charactersIgnoringModifiers?.lowercased() {
                switch key {
                case "a":
                    editor.selectAll(nil)
                    return true
                case "c":
                    editor.copy(nil)
                    return true
                case "v":
                    editor.paste(nil)
                    return true
                case "x":
                    editor.cut(nil)
                    return true
                default:
                    break
                }
            }
        }

        let wordNavigationModifier =
            flags.contains(.control) || flags.contains(.option)
        guard wordNavigationModifier else { return false }

        let extendsSelection = flags.contains(.shift)

        // Hardware key codes are layout-independent for these navigation keys.
        switch event.keyCode {
        case 51: // delete_or_backspace
            editor.deleteWordBackward(nil)
            return true
        case 123: // left arrow
            if extendsSelection {
                editor.moveWordLeftAndModifySelection(nil)
            } else {
                editor.moveWordLeft(nil)
            }
            return true
        case 124: // right arrow
            if extendsSelection {
                editor.moveWordRightAndModifySelection(nil)
            } else {
                editor.moveWordRight(nil)
            }
            return true
        case 126: // up arrow
            if extendsSelection {
                editor.moveParagraphBackwardAndModifySelection(nil)
            } else {
                editor.moveToBeginningOfParagraph(nil)
            }
            return true
        case 125: // down arrow
            if extendsSelection {
                editor.moveParagraphForwardAndModifySelection(nil)
            } else {
                editor.moveToEndOfParagraph(nil)
            }
            return true
        default:
            return false
        }
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else { return 0 }
        return width * height
    }
}
