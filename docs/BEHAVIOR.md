# WindowsMac behavioural specification

This document is the source of truth for user-visible keyboard behaviour.

## Global Windows-style shortcuts

Outside terminal applications, the default mappings are:

| Physical shortcut | macOS action |
|---|---|
| Ctrl+C | Cmd+C |
| Ctrl+V | Cmd+V |
| Ctrl+X | Cmd+X |
| Ctrl+A | Cmd+A |
| Ctrl+Z | Cmd+Z |
| Ctrl+Shift+Z | Cmd+Shift+Z |
| Ctrl+F | Cmd+F |
| Ctrl+S | Cmd+S |
| Ctrl+P | Cmd+P |
| Ctrl+T | Cmd+T |
| Ctrl+W | Cmd+W |
| Ctrl+Shift+T | Cmd+Shift+T |
| Alt+Tab | Cmd+Tab |

## Terminal applications

Unix Control shortcuts must remain untouched in terminal applications. At minimum:

- Ctrl+C
- Ctrl+D
- Ctrl+A
- Ctrl+Z
- Ctrl+W

The initial terminal allowlist includes Apple Terminal, iTerm2 and Ghostty, and must remain configurable.

## Finder

| Shortcut | Behaviour |
|---|---|
| Enter | Open selected file or folder |
| F2 | Rename selected item |
| Alt+Left | Navigate backward in Finder history |
| Alt+Right | Navigate forward in Finder history |
| Alt+Up | Navigate to parent folder |
| Alt+Down | Open selected child folder |
| Ctrl+L | Open WindowsMac Finder address bar |
| Win+E | Show/open Finder |

### Finder address bar

Ctrl+L displays an editable text field containing the POSIX path of the active Finder window.

Expected behaviour:

- Ctrl+A selects the complete path.
- Ctrl+C copies it.
- Ctrl+V pastes a replacement path.
- Enter navigates the active Finder window to that path.
- Escape dismisses the field.
- The field must receive focus immediately.

## Window management

The Windows key is treated as the window-management modifier.

| Shortcut | Target state |
|---|---|
| Win+Left | Left half |
| Win+Right | Right half |
| Win+Up | Top half, or maximize if already top half |
| Win+Down | Bottom half |

Successive directional commands resolve from the actual current window geometry, not only from the last command.

Examples:

- Left half + Win+Up -> top-left quarter.
- Left half + Win+Down -> bottom-left quarter.
- Right half + Win+Up -> top-right quarter.
- Right half + Win+Down -> bottom-right quarter.
- Top half + Win+Up -> maximized visible frame.

Maximized means filling the screen's usable visible frame; it must not enter macOS native fullscreen / a separate Space.

## Window states

The helper recognises these logical states:

- normal
- maximized
- leftHalf
- rightHalf
- topHalf
- bottomHalf
- topLeft
- topRight
- bottomLeft
- bottomRight

State recognition must tolerate small coordinate differences caused by window borders and macOS layout rounding.

## Safety

WindowsMac must be instantly disableable. A future emergency shortcut is reserved as Ctrl+Alt+Win+F12.

If the helper is unavailable, normal keyboard remaps must continue working and advanced actions should fail safely without blocking input.
