# WindowsMac

WindowsMac is a lightweight compatibility layer that makes a Windows keyboard workflow feel natural on macOS.

It combines:

- **Karabiner-Elements 16+** for low-level, application-aware key remapping.
- **WindowsMac**, a native Swift helper for stateful actions such as Windows-style window snapping and Finder-specific behaviour.

## Current implementation

Implemented in the bootstrap:

- Windows-style `Ctrl+C/V/X/A/Z/F/S/P/T/W/L` outside terminal applications.
- Unix `Ctrl` shortcuts preserved in Apple Terminal, iTerm2 and Ghostty.
- Reliable `Alt+Tab` using Karabiner's modifier-aware `to_if_other_key_pressed`.
- Finder:
  - `Enter` opens the selected item while remaining normal inside text fields / rename fields.
  - `F2` starts rename.
  - `Alt+Left` / `Alt+Right` navigate Finder history.
  - `Alt+Up` goes to the parent folder.
  - `Alt+Down` opens the selected child only when it is a folder.
  - `Ctrl+L` opens a native editable address bar anchored to the active Finder window.
  - the exact Finder window is captured by Finder window ID when `Ctrl+L` is pressed, so submitting the path cannot accidentally navigate a different Finder window.
  - the address bar shows the current POSIX path, receives focus immediately, supports `Ctrl+A/C/V`, navigates with `Enter`, and closes with `Escape`.
  - path normalization is syntax-only and nonblocking; Finder/AppleScript performs existence, folder and package validation asynchronously.
  - POSIX paths, `~`, quoted paths and `file://` URLs are supported; missing paths, regular files and package folders are rejected without navigation.
  - denied Finder Automation permission produces an explicit alert with a shortcut to macOS Automation settings.
- Window management:
  - `Win+Left/Right/Up/Down` uses Karabiner `send_user_command` and the native helper.
  - successive `Win+Up` from the top half maximizes without entering native fullscreen.
  - quarter-screen transitions from left/right halves.
- `Win+E` focuses Finder.
- `Win+L` locks the session.
- Menu-bar ON/OFF backed by the `windowsmac_enabled` Karabiner variable.
- Emergency disable: `Ctrl+Alt+Win+F12`.
- AppKit ↔ Accessibility coordinate conversion and multi-display-aware geometry.
- Native `.app` bundle build script.
- CI for Karabiner JSON, app `Info.plist`, Swift build/tests and app bundling.

Not yet implemented:

- IDE-integrated terminal detection (for example VS Code's integrated terminal).
- Per-device enablement UI.
- Fully layout-independent Finder history navigation for every non-ANSI keyboard layout.

See [`docs/BEHAVIOR.md`](docs/BEHAVIOR.md) for the behavioural contract.

## Architecture

```text
Physical Windows keyboard
          |
          v
Karabiner-Elements 16+
          |
          +--> stateless remaps
          |
          +--> send_user_command (Unix datagram)
                       |
                       v
                  WindowsMac
                  - WindowManager
                  - FinderController
                  - FinderAutomation
                  - Finder address bar
                  - Menu-bar state
                       |
                       v
                WindowsMacCore
                - snap states
                - geometry
                - coordinate conversion
                - path normalization
                - AppleScript string encoding
                - command model
```

`WindowSnapState` contains only actual snap states. A normal window is represented by the absence of a snap state, so maximized and normal windows are never conflated.

## Build

```bash
swift test
zsh Scripts/build-app.sh
```

The app bundle is produced at:

```text
dist/WindowsMac.app
```

## Karabiner validation

```bash
zsh Scripts/lint-karabiner.sh
```

If Karabiner is installed, its own `--lint-complex-modifications` validator is used after JSON syntax validation.

## Permissions

WindowsMac requires:

- **Accessibility** for window positioning and resizing.
- **Automation → Finder** for reading Finder paths, identifying the active Finder window and navigating that exact window.

The application bundle declares `NSAppleEventsUsageDescription`, and the UI surfaces a direct macOS Settings shortcut when Finder Automation is denied.

## Requirements

- macOS 14+
- Karabiner-Elements 16+

## License

No open-source license has been granted at this stage. The repository is public for development and visibility purposes; all rights remain reserved unless a license is added later.
