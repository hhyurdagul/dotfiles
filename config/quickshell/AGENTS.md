# Quickshell Architectural & Agent Guide (AGENTS.md)

This document provides technical instructions, constraints, and architectural guidelines for AI agents and maintainers modifying the Quickshell configuration in this repository.

---

## 1. Singletons & Module Registration (`qmldir`)

- **`Theme.qml`** and **`NotifManager.qml`** are declared with `pragma Singleton`.
- Both MUST be registered inside [`config/quickshell/qmldir`](./qmldir):
  ```
  singleton Theme 1.0 Theme.qml
  singleton NotifManager 1.0 NotifManager.qml
  ```
- Any component importing `"../"` can access `Theme` and `NotifManager` directly.
- **Rule**: NEVER hardcode colors, margins, or radiuses inside individual components. Reference `Theme.col*`, `Theme.popupTopMargin`, `Theme.cardRadius`, and `Theme.cardBorderColor`.

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

---

## 5. Subprocess Execution (`Process` & `SplitParser`)

- `Quickshell.Io.Process` stdout with `SplitParser` fires `onRead: data => {}` **per single line**.
- For multi-line command output (e.g. `ps`, `wttr.in`, `/sys/class/power_supply`):
  - Either format the output into a single JSON line on the shell side before printing:
    ```bash
    echo "{\"cap\": $cap, \"status\": \"$st\", \"ac\": $ac}"
    ```
  - Or accumulate lines across `onRead` callbacks and reset when `running` changes to `false`.

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
