# Quickshell Architectural & Agent Guide (AGENTS.md)

This document provides technical instructions, constraints, and architectural guidelines for AI agents and maintainers modifying the Quickshell configuration in this repository.

---

## 1. Singletons & Module Registration (`qmldir`)

- These root files are declared with `pragma Singleton`:
  - **`Theme.qml`**: colors, sizes, fonts; `isDark` switches Ember/Dust (wallpaper-derived) at runtime.
  - **`NotifManager.qml`**: notification server, toasts, history, DND.
  - **`Dictation.qml`**: Handy recording state.
  - **`Compositor.qml`**: the only Niri IPC client (workspaces, windows, focused output, focus actions).
  - **`SystemStats.qml`**: CPU and RAM usage from `/proc`.
  - **`NetworkStatus.qml`**: Wi-Fi state, scan/connect, and throughput.
  - **`IdleInhibitor.qml`**: `idle-inhibit.service` state and toggle.
  - **`CameraStatus.qml`**: whether a `/dev/video*` node is in use.
- All MUST be registered inside [`config/quickshell/qmldir`](./qmldir):
  ```
  singleton Theme 1.0 Theme.qml
  singleton NotifManager 1.0 NotifManager.qml
  singleton Dictation 1.0 Dictation.qml
  singleton Compositor 1.0 Compositor.qml
  singleton SystemStats 1.0 SystemStats.qml
  singleton NetworkStatus 1.0 NetworkStatus.qml
  singleton IdleInhibitor 1.0 IdleInhibitor.qml
  singleton CameraStatus 1.0 CameraStatus.qml
  ```
- Any component importing `"../"` can access every singleton directly.
- Follow the existing singleton shape: a `QtObject` root holding `Process`,
  `FileView`, `Socket` and `Timer` children in `property var` slots.
- **Rule**: NEVER hardcode colors, margins, or radiuses inside individual components. Reference `Theme.col*`, `Theme.popupTopMargin`, `Theme.cardRadius`, and `Theme.cardBorderColor`.
- **Rule**: Bars, toasts, and overlays are instantiated once per screen. State that
  polls or watches the system (timers, subprocesses, file reads) MUST live in a
  singleton so it runs once regardless of screen count; widgets only bind to it.
  Per-widget processes are fine only while that widget's popup is open.
  Not yet migrated: `BatteryWidget` (sysfs `FileView` reloads) and the weather
  fetch in `CenterInfo` still run once per bar.
- **Rule**: Niri is the only compositor. Talk to it through `Compositor`; never
  spawn `niri msg` from widgets.

---

## 2. Window & Anchor Architecture

### Bar Layout (`shell.qml`)
- Uses a `PanelWindow` anchored to `top: true, left: true, right: true` with `implicitHeight: 34`.
- **3-Section Layout Structure**:
  - `leftRow`: `anchors.left: parent.left; anchors.leftMargin: 12`
  - `centerInfo`: `anchors.centerIn: parent` (mathematically locked to screen center)
  - `rightRow`: `anchors.right: parent.right; anchors.rightMargin: 12`

### Layout Rules (Qt Quick Layouts)
- **CRITICAL**: Children inside `RowLayout` or `ColumnLayout` MUST NOT use `anchors.*` (e.g. `anchors.verticalCenter`).
- **Use `Layout.alignment: Qt.AlignVCenter` instead.** Violating this causes runtime warnings: `Detected anchors on an item that is managed by a layout. This is undefined behavior.`

---

## 3. Popup Window Anchoring (`PopupWindow`)

### Correct Pattern (Native Wayland Item Tracking)
```qml
PopupWindow {
    id: popup
    visible: dropdownOpen
    anchor.window: barWindow
    anchor.item: iconContainer     // or root item
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    implicitWidth: popupWidth
    implicitHeight: popupHeight + Theme.popupTopMargin
    color: "transparent"

    Rectangle {
        id: cardRect
        anchors.fill: parent
        anchors.topMargin: Theme.popupTopMargin  // Creates the floating gap
        color: Theme.colBg
        radius: Theme.cardRadius
        border.color: Theme.cardBorderColor
        border.width: Theme.cardBorderWidth
    }

    Loader {
        anchors.fill: cardRect
        anchors.margins: 12
    }
}
```

### Why This Architecture?
1. **Never use manual JavaScript math (`anchor.rect.x`) for popup placement**: In QML, calling functions like `mapToItem()` inside property bindings does NOT register reactive property dependencies, causing popups to render at `(0, 0)` (far left) upon first show.
2. **`anchor.item` is C++ native**: Quickshell's Wayland surface engine tracks the item's compositor surface position with zero lag.
3. **Floating gap via `anchors.topMargin`**: Wayland positioners ignore `PopupAnchor.margins`. Placing `anchors.topMargin: Theme.popupTopMargin` on the internal card inside the transparent window ensures the visible card floats consistently.

---

## 4. Notification Subsystem

- Handled entirely within Quickshell via `NotificationServer` in [`NotifManager.qml`](./NotifManager.qml).
- `activeToasts`: Temporary list of notifications displayed as floating toasts in [`NotificationToasts.qml`](./components/NotificationToasts.qml).
- `history`: Persistent list of received notifications.
- `dndEnabled`: When active, incoming notifications skip `activeToasts` (suppressing popups) but are appended to `history`.
- `onNotification` fires only for new IDs. A replacement (`notify-send -r`) reuses
  the `Notification` object and only changes its properties, so `watch()` connects
  their change signals and `publish()` refreshes the history entry and toast.

---

## 5. Subprocess Execution (`Process` & `SplitParser`)

- `Quickshell.Io.Process` stdout with `SplitParser` fires `onRead: data => {}` **per single line**.
- For multi-line command output (e.g. `ps`, `top`, `nmcli`), prefer `StdioCollector`
  and parse `text` in `onStreamFinished`. Alternatives:
  - Format the output into a single JSON line on the shell side before printing:
    ```bash
    echo "{\"cap\": $cap, \"status\": \"$st\", \"ac\": $ac}"
    ```
  - Or accumulate lines across `onRead` callbacks and reset when `running` changes to `false`.
- Read files (`/proc`, `/sys`, caches) with `FileView` and `reload()`, not by
  spawning `cat`/`free`.
- Launch GUI apps and fire-and-forget actions (`pavucontrol`, `kitty -e btop`,
  `nm-connection-editor`, `lock-screen`, `session-exit`, `systemctl reboot`) with
  `Quickshell.execDetached([...])`. A `Process` child dies with its object when
  Quickshell reloads or restarts.
- Prefer events over polling: `CameraStatus` reacts to `inotifywait` events.
  When adding a tool, make sure it is on the Quickshell service's `PATH`
  (`home/hhyurdagul/services.nix`).

---

## 6. Symmetrical Spacing Conventions

- Top bar items on the right follow an **Icon-First** format: `󰍛 2%`, `󰾆 0%`, `󰕾 50%`, `󰁹 95%`.
- Containers in `rightRow` MUST NOT declare unilateral margins (like `Layout.rightMargin: 8`).
- Spacing is uniformly managed by [`Separator.qml`](./components/Separator.qml):
  - `Layout.leftMargin: 8`
  - `Layout.rightMargin: 8`

---

## 7. File Permissions

- All `.qml`, `.json`, `.toml`, `.conf` files: `chmod 644` (`-rw-r--r--`).
- All directories: `chmod 755` (`drwxr-xr-x`).
- Executable Python/shell scripts: `chmod 755` (`-rwxr-xr-x`).
