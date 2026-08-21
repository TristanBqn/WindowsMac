# WindowsMac behavioural specification

This document is the source of truth for user-visible behaviour.

Status markers:

- **Implemented**: present in the current bootstrap.
- **Planned**: specified but not yet intercepted.

## Global Windows-style shortcuts

Outside terminal applications:

| Physical shortcut | macOS action | Status |
|---|---|---|
| Ctrl+C | Cmd+C | Implemented |
| Ctrl+V | Cmd+V | Implemented |
| Ctrl+X | Cmd+X | Implemented |
| Ctrl+A | Cmd+A | Implemented |
| Ctrl+Z | Cmd+Z | Implemented |
| Ctrl+Shift+Z | Cmd+Shift+Z | Implemented |
| Ctrl+F | Cmd+F | Implemented |
| Ctrl+S | Cmd+S | Implemented |
| Ctrl+P | Cmd+P | Implemented |
| Ctrl+T | Cmd+T | Implemented |
| Ctrl+W | Cmd+W | Implemented |
| Ctrl+Shift+T | Cmd+Shift+T | Implemented |
| Ctrl+L | Cmd+L, except Finder | Implemented |
| Alt+Tab | Cmd+Tab | Implemented |

## Terminal applications

Unix Control shortcuts remain untouched in Apple Terminal, iTerm2 and Ghostty.

IDE-integrated terminals require a separate focus-aware rule and remain planned.

## Finder

| Shortcut | Behaviour | Status |
|---|---|---|
| Enter | Open selected file/folder | Implemented |
| F2 | Rename selected item | Implemented |
| Alt+Left | Navigate backward | Implemented; ANSI mapping currently |
| Alt+Right | Navigate forward | Implemented; ANSI mapping currently |
| Alt+Up | Parent folder | Implemented |
| Alt+Down | Enter selected folder only | Implemented |
| Ctrl+L | Windows-style editable address bar | Implemented |
| Win+E | Focus/open Finder | Implemented |

`Enter` remains a normal Return key while a Finder text element has focus, including filename rename and search fields.

### Finder address bar

Implemented behaviour:

- `Ctrl+L` opens a lightweight native panel anchored near the top of the active Finder window.
- The exact Finder window ID is captured when `Ctrl+L` is pressed. Submitting later targets that same Finder window rather than whichever Finder window happens to be frontmost at submission time.
- The field contains the normalized POSIX path of the current Finder folder and receives focus immediately.
- `Ctrl+A`, `Ctrl+C` and `Ctrl+V` behave as under Windows through the normal WindowsMac Control remaps.
- `Enter` submits asynchronously so slow network/cloud path resolution does not block the panel UI.
- `Escape` closes the field and returns focus to Finder.
- Clicking another application dismisses the panel without stealing focus back.
- POSIX paths, `~`, quoted paths and `file://` URLs are accepted.
- Path normalization itself never probes the filesystem. Finder/AppleScript resolves the destination and rejects missing paths, regular files and package folders.
- Finder virtual locations that do not expose a filesystem path fail safely instead of fabricating a path.
- AppleScript returns structured descriptor lists for Finder context/navigation status rather than encoding path and geometry into delimiter-separated text.
- User-supplied paths are encoded as AppleScript expressions so quotes, backslashes and control characters cannot break the script source.
- Finder Automation denial produces an explicit permission dialog with a shortcut to macOS Automation settings.
- The app bundle declares `NSAppleEventsUsageDescription`, as required for Apple Events.
- The AppleScript runtime is initialized on the main thread at app launch before Finder work is dispatched to background tasks.

## Window management

The physical Windows key is the macOS Command key on a standard PC keyboard.

| Shortcut | Target state | Status |
|---|---|---|
| Win+Left | Left half | Implemented |
| Win+Right | Right half | Implemented |
| Win+Up | Top half, then maximize | Implemented |
| Win+Down | Bottom half | Implemented |
| Win+E | Finder | Implemented |
| Win+L | Lock session | Implemented |

Successive commands are derived from the window's actual geometry, with a tolerance for borders and rounding.

Examples:

- left half + Win+Up → top-left quarter
- left half + Win+Down → bottom-left quarter
- right half + Win+Up → top-right quarter
- right half + Win+Down → bottom-right quarter
- top half + Win+Up → maximized visible frame

Maximized means `NSScreen.visibleFrame`; it never requests macOS native fullscreen.

A normal window is not a `WindowSnapState`. Its pre-snap frame is retained separately by the window manager for future restore behaviour.

## Coordinate systems

AppKit and Accessibility use different vertical origins. WindowsMac converts explicitly between them before reading or applying window frames. Screen selection is based on the largest intersection with the current window, so negative and non-zero display origins are supported.

## Safety

All Karabiner mappings depend on:

```text
windowsmac_enabled = 1
```

The menu-bar toggle changes that variable through `karabiner_cli`.

Emergency disable:

```text
Ctrl + Alt + Win + F12
```

sets the variable to `0` directly in Karabiner, without depending on the Swift helper.

If the helper crashes, the variable is left unchanged, so stateless keyboard remaps continue to function. Advanced `send_user_command` actions fail without blocking ordinary input.
