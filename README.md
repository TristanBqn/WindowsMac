# WindowsMac

WindowsMac is a lightweight compatibility layer that makes a Windows keyboard workflow feel natural on macOS.

The project deliberately separates two responsibilities:

- **Karabiner-Elements** handles low-level key remapping and application-specific keyboard rules.
- **WindowsMac.app** is a small native Swift helper for stateful macOS behaviours such as window snapping and Finder path handling.

## Initial goals

- Windows-style `Ctrl` shortcuts in standard macOS applications.
- Preserve Unix `Ctrl` shortcuts in terminals.
- Finder behaviour closer to Windows Explorer:
  - `Enter` opens the selected item.
  - `F2` renames the selected item.
  - `Alt+Left` / `Alt+Right` navigate history.
  - `Alt+Up` navigates to the parent folder.
  - `Alt+Down` opens the selected child folder.
  - `Ctrl+L` opens a path/address field for the active Finder window.
- Windows-style window management:
  - `Win+Left` / `Right` / `Up` / `Down` snap the active window.
  - Successive directional commands support quarter-screen layouts.
  - `Win+Up` from the top-half state maximizes the window without entering macOS fullscreen.
- `Win+E` opens Finder.
- `Win+L` locks the Mac.

## Architecture

```text
Physical keyboard
      |
      v
Karabiner-Elements
      |
      +--> standard remaps (Ctrl+C -> Cmd+C, etc.)
      |
      +--> internal action keys
                 |
                 v
          WindowsMac.app
          - Window manager
          - Finder controller
          - Finder address bar
          - Preferences / menu bar
```

## Repository layout

```text
WindowsMac/
├── App/                 # Native Swift helper
├── Karabiner/           # Karabiner complex-modification rules
├── Scripts/             # Install/update/uninstall helpers
├── Tests/               # Unit tests for state and geometry logic
└── docs/                # Architecture and behavioural specification
```

## Status

Early development. The first milestone is a reliable keyboard compatibility layer and a minimal native helper that can receive actions from Karabiner.

## License

No open-source license has been granted at this stage. The repository is public for development and visibility purposes; all rights remain reserved unless a license is added later.
