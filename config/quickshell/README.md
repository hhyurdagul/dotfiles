# Quickshell Status Bar & Notification Center

A modern, native Wayland status bar, notification center, and system widget suite built using **[Quickshell](https://quickshell.outfoxxed.me/)** (Qt Quick / QML) for **Niri** on NixOS.

Uses the **Catppuccin** palettes, switched at runtime: **Mocha** in dark mode and **Latte** in light mode. It has a 3-section layout, native floating popups, and full hardware & notification integration.

---

## 🌟 Key Features

### 1. True 3-Section Layout
- **Left**: Named Niri workspaces 1–10, debounced mouse-wheel switching, app icons, and the active window title.
- **Center (Mathematically Centered)**: Notification center pill (with unread count & DND status), clickable Date pill (opens monthly Calendar), and Weather forecast pill. The weather popup shows the rain chance for the next five 3-hour forecast slots, from the current hour on (continuing into tomorrow). A failed fetch is retried after a minute; a good one is refreshed hourly.
- **Right**: System status indicators and interactive dropdown menus separated by symmetrical dividers.
- **Right, immediately after the tray**: Clipboard history. Search, copy, delete, and confirmed clear of text and image entries captured by `cliphist`.

### 2. Native Dropdown Popup Engine
- Every widget popup floats **8px below the bar** with clean rounded cards (`cardRadius: 12px`, subtle 1px border).
- Powered natively by Quickshell's `PopupAnchor` (`anchor.item: iconContainer`), providing instant, lag-free anchoring without manual coordinate mapping.
- Native Wayland `PopupWindow.grabFocus` provides keyboard focus and click-outside dismissal; changing application/workspace also dismisses open menus.

### 3. Native Desktop Notification System

- Clicking a toast or history entry invokes the app's default notification action
  and explicitly focuses its most recently used matching window (by Niri
  `app_id` and window ID) after the popup releases focus.
  Without an action or open window, it launches the supplied
  desktop entry.
  Notifications remain tracked while in history so their actions stay usable.
  Apps must supply a default action or a recognizable app name/desktop entry.
- **Built-in Notification Server (`NotifManager.qml`)**: Replaces external daemons like SwayNC or Dunst.
  A replaced notification (`notify-send -r`, progress updates) updates its
  history entry in place, moves it to the top, and shows its toast again with
  the new text.
- **Floating Toasts (`NotificationToasts.qml`)**: Real-time notification banners in the top-right corner with 5-second auto-dismiss.
- **Do Not Disturb (DND)**:
  - **Left Click** on center bell: Opens notification history dropdown with 1-click dismissal.
  - **Right Click** on center bell: Toggles Do Not Disturb. When DND is active, toasts are suppressed while notifications silently accumulate in history.

### 4. Interactive Hardware & System Dropdowns
- **CPU (`CpuWidget.qml`)**: Top 10 processes by current CPU usage (PID, Name, CPU%), measured by `top` over one second and refreshed every 3 seconds while the popup is open, plus a `btop` terminal shortcut.
- **Memory (`MemoryWidget.qml`)**: Live RAM usage summary (Used / Total, as `free` counts it) and top memory-consuming processes.
- **Volume (`VolumeWidget.qml`)**:
  - Scroll wheel: **±5% volume step**.
  - `Shift` + Scroll: **±1% fine-tuning**.
  - Dynamic audio glyphs (Headphones `󰋋`, Bluetooth `󰂰`, Speaker `󰕾`, Mute `󰖁`).
  - Right-click opens `pavucontrol`; so does **Advanced Audio Settings** in the popup.
- **Battery & Power Profile (`BatteryWidget.qml`)**:
  - Unified battery indicator reading directly from kernel sysfs (`/sys/class/power_supply/`).
  - Integrated 1-click power profile switcher (`Performance`, `Balanced`, `Power Saver` via `powerprofilesctl`).
- **Network & Wi-Fi (`WifiWidget.qml`)**: Live upload/download throughput speed and interactive network list. If `nmcli` cannot connect (for example, a new secured network), `nm-connection-editor` opens.
- **Bluetooth (`BluetoothWidget.qml`)**: Toggle power, scan for 30 seconds, and pair/connect headphones. Live BlueZ state tracks every connected device. Connected devices that report a battery level show a live percentage beside their name, with warning colors at 30% and 15%; the indicator is hidden when the level is unavailable. Repeated names are grouped with the connected entry first; **Show all entries** exposes individual saved addresses. The popup stays open to show progress and errors. Pairing uses a temporary `NoInputNoOutput` agent for devices such as headphones; devices requiring a PIN or passkey need a Bluetooth manager with an interactive pairing agent.
- **System Indicators**:
  - **Camera (`CameraIndicatorWidget.qml`)**: Red pill with `REC` badge while any process holds a `/dev/video*` node open.
  - **Microphone (`MicIndicatorWidget.qml`)**: Orange mic icon while any app captures from an input device (dictation, calls, recordings); sink monitors don't count.
  - **Idle Inhibitor (`IdleIndicatorWidget.qml`)**: Click to toggle the idle inhibitor (`idle-toggle`, also on Super+Alt+I). While it is on, the icon is highlighted and `idle-inhibit.service` holds a systemd idle lock, so the screen doesn't dim, turn off, lock, or suspend. The idle daemon itself keeps running.
  - **Power Menu (`PowerWidget.qml`)**: Lock, Suspend, Logout, Reboot, and Shutdown. Logout uses `session-exit`, which locks before leaving the Niri session. Actions run detached, so they survive a Quickshell restart.

---

## 🎨 Theme & Customization

All visual styles, colors, margins, radiuses, and fonts are centralized in **[`Theme.qml`](./Theme.qml)**.
`Theme.isDark` follows `$XDG_STATE_HOME/theme/mode` (written by darkman via
`theme-switcher`), and every color switches between Mocha and Latte without a
restart.

```qml
// Theme.qml highlights
readonly property color colBg: isDark ? "#1e1e2e" : "#eff1f5"      // Base background
readonly property color colGreen: isDark ? "#a6e3a1" : "#40a02b"   // Battery, Volume, BT
readonly property color colRed: isDark ? "#f38ba8" : "#d20f39"     // Recording, Critical, Poweroff
readonly property color colYellow: isDark ? "#f9e2af" : "#df8e1d"  // Notifications, Idle
readonly property color colBlue: isDark ? "#89b4fa" : "#1e66f5"    // CPU, Bluetooth
readonly property color colPink: isDark ? "#f5c2e7" : "#ea76cb"    // Network
readonly property int popupTopMargin: 8    // Floating gap between top bar and menus
readonly property int cardRadius: 12       // Corner radius for all popups and toasts
readonly property string fontFamily: "JetBrainsMono Nerd Font"
```

To tweak any aspect of the UI, edit `Theme.qml`. Direct edits to the running configuration hot-reload. With the Home Manager setup, rebuild to install the changes, then run `systemctl --user restart quickshell` to load the new Nix store files; replacing the configuration symlinks does not reliably trigger hot-reload.

---

## 📁 Directory Structure

```
config/quickshell/
├── shell.qml                         # Root panel window & 3-section layout
├── qmldir                            # QML module & singleton registration
├── Theme.qml                         # Catppuccin Mocha/Latte theme singleton (runtime switch)
├── Compositor.qml                    # Shared Niri IPC backend (workspaces, windows, focus)
├── NotifManager.qml                  # NotificationServer singleton & history
├── Dictation.qml                     # Handy recording state singleton (PipeWire)
├── SystemStats.qml                   # Shared CPU / RAM sampling from /proc
├── NetworkStatus.qml                 # Shared Wi-Fi state (nmcli) & throughput (/proc/net/dev)
├── IdleInhibitor.qml                 # Shared idle-inhibit.service state & toggle
├── CameraStatus.qml                  # Shared inotify-driven camera-in-use detection
├── components/
│   ├── DropdownWidget.qml            # Base component for right-side dropdowns
│   ├── NotificationToasts.qml        # Floating notification banners (top-right)
│   ├── OnScreenDisplay.qml           # Volume / mute / brightness indicator (IPC "osd")
│   ├── DictationOverlay.qml          # Bottom-center card while Handy records
│   ├── CenterInfo.qml                # Center Notifications, Calendar & Weather
│   ├── WorkspaceBar.qml              # Workspace switcher with debounced scroll
│   ├── WindowInfo.qml                # Active window title
│   ├── SystemTrayWidget.qml          # StatusNotifier tray icons & menus
│   ├── ClipboardWidget.qml           # Clipboard history dropdown (cliphist)
│   ├── CpuWidget.qml                 # CPU usage & top processes dropdown
│   ├── MemoryWidget.qml              # RAM usage & top processes dropdown
│   ├── VolumeWidget.qml              # WirePlumber volume & sink manager
│   ├── BatteryWidget.qml             # Battery status & power profile switcher
│   ├── WifiWidget.qml                # Network speed & Wi-Fi dropdown
│   ├── BluetoothWidget.qml           # Bluetooth device manager
│   ├── CameraIndicatorWidget.qml     # Active camera indicator
│   ├── MicIndicatorWidget.qml        # Microphone-in-use indicator
│   ├── IdleIndicatorWidget.qml       # Idle inhibitor toggle
│   ├── Clock.qml                     # Clock widget
│   ├── PowerWidget.qml               # Lock / Suspend / Reboot / Poweroff menu
│   └── Separator.qml                 # Symmetrical vertical divider
└── scripts/
    ├── weather.py                    # Weather fetcher (wttr.in), run as `weather-status`
    └── clipboard-history.py          # cliphist helper for ClipboardWidget, run as `clipboard-history`
```

---

## 🔧 System Requirements

Shared state lives in singletons, so the work below runs once however many
screens have a bar:

- `Compositor.qml` owns all compositor state; widgets do not launch their own
  compositor processes.
- `SystemStats.qml` re-reads `/proc/stat` and `/proc/meminfo` every 3 seconds
  through `FileView`; no `cat`/`free` subprocesses.
- `NetworkStatus.qml` polls `nmcli` every 5 seconds and samples
  `/proc/net/dev` through `FileView`; a full Wi-Fi rescan runs only when the
  popup opens or after a connection attempt.
- `IdleInhibitor.qml` checks `idle-inhibit.service` every 10 seconds and right
  after a click (the key binding toggles it too).
- `CameraStatus.qml` runs one `inotifywait` on the `/dev/video*` nodes; their
  open/close events trigger a single `fuser` check, and a second watcher on
  `/dev` re-arms it when a camera is plugged in or removed. Nothing polls.

The session launcher must pass the Niri session's `WAYLAND_DISPLAY` and
`NIRI_SOCKET`. Do not reuse stale environment variables from a previous session.

- **Niri 26.04**: Two native Unix sockets connect to `NIRI_SOCKET`: one subscribes
  to the JSON `EventStream` (including its initial complete state), the other sends
  actions. Disconnected sockets are reconnected; Niri state is not polled.
  Workspace buttons always show names **1–10**, regardless of their monitor-local
  indices. Focus uses an explicit IPC
  `Name` reference: the CLI argument `focus-workspace 6` would instead mean index
  6 on the current output. Wheel navigation moves through names 1–10, clamped at
  the ends, crossing outputs where the configured workspace lives. Unnamed dynamic
  Niri workspaces are not numbered in the bar.
- **Popups**: Require Quickshell **0.3.0 or newer**, specifically
  [`PopupWindow.grabFocus`](https://quickshell.org/docs/v0.3.0/types/Quickshell/PopupWindow/).
  An outside click dismisses the popup rather than leaving it open for custom
  handling. As with native popup grabs generally, clicking another control may
  first dismiss the existing popup.
- **Notifications and overlays**: Notification default actions, history, DND,
  app matching, weather, hardware dropdowns,
  and dictation are independent of the compositor. Dictation follows the backend's
  focused output. OSD uses the helper-supplied output, or the backend's focused
  output when none is supplied; an unavailable output falls back to the first screen.
- **Logout**: Calls the packaged `session-exit` helper, which uses Niri's native
  session exit.

Screenshots are compositor shortcuts rather than Quickshell widgets. Niri uses
its native screenshot UI for **Print** and focused-screen capture for
**Super+Print**. See the root README for the complete shortcut and
screenshot-storage details.

Volume, speaker/microphone mute, and brightness keys show a short indicator at
the bottom of the focused screen. Brightness targets that screen's laptop
backlight or external monitor via DDC, and displays the value read back from the
hardware. Super+volume uses those same brightness steps. Super+mute toggles the
focused external monitor between 0 and 100, and does nothing on the internal
panel. The indicator does not take keyboard focus or intercept clicks.

While Handy records, a card at the bottom of the focused screen shows a pulsing
dot, the microphone level, and the elapsed time; its close button runs
`handy --cancel`, and the rest of the card passes clicks through. Handy's own
overlay stays off: WebKitGTK paints only fragments of its transparent window.

- **Compositor**: Niri 26.04
- **Shell**: Quickshell (`quickshell`) **>= 0.3.0**, with Wayland and Io modules
- **Session helpers on PATH**: `session-exit`, `lock-screen`, `idle-toggle`, `desktop-control`, `weather-status`, `clipboard-history`, and `handy` for dictation cancellation
- **User services**: `idle-inhibit.service` (started and stopped by `idle-toggle`)
- **IPC environment**: Reachable `NIRI_SOCKET`
- **Tools**:
  - `wireplumber` / `wpctl` (Audio), `pavucontrol` (mixer)
  - `power-profiles-daemon` / `powerprofilesctl` (Power management)
  - `bluez` / `bluetoothctl` (Bluetooth)
  - `networkmanager` / `nmcli` (Wi-Fi), `nm-connection-editor` (fallback for new networks)
  - `inotify-tools` / `inotifywait` and `psmisc` / `fuser` (Camera indicator)
  - `procps` / `top`, `ps` (process lists), `kitty` and `btop` (System Monitor button)
  - `python3` with `urllib` (Weather)
  - `systemctl` (power/session services, idle inhibitor state)

## Verification after integration

Integration smoke: the full shell loaded in a nested Niri 26.04 session on
Quickshell 0.3.0 and rendered its bar and window. Native named-workspace actions,
window focus/title updates, keyboard switching, display
power commands, and screenshot capture were exercised. Both generated themes passed
Niri validation; the NixOS build, Nix formatting, statix, and deadnix passed.
Two longer-lived nested instances later stopped answering IPC; short probes of
both the empty configuration and the migrated full shell accepted screenshots
and exited natively with compositor status 0. Cause of the nested stall is not
established; this is not proof of physical-session stability. The native quit
CLI can report EOF when the compositor exits before writing its reply.
Physical monitor modes/gestures, notification delivery (the host owns the D-Bus
name), popup interaction, hardware controls, and full session logout still need
checking after activation in a real session:

```sh
quickshell --version
systemctl --user restart quickshell
journalctl --user -u quickshell -b --no-pager
# Inspect the same native state/event protocol used by the backend.
niri msg --json workspaces
niri msg --json windows
niri msg --json focused-output
niri msg --json event-stream
```

Stop the foreground event stream with Ctrl+C. Check workspace buttons 1, 6, and
10 on their configured outputs, wheel boundaries,
window-title changes, notification clicks (`notify-send -a kitty "Focus test"`
with a Kitty window open), notification replacement
(`id=$(notify-send -p Test one); notify-send -r "$id" Test two`), and
outside-click/Escape dismissal of every menu.
While Handy records, change focused outputs and cancel from the dictation card;
exercise volume/brightness keys and confirm OSD placement. Open and close the
camera (the `REC` pill should follow within a second), toggle the idle
inhibitor from the bar and with Super+Alt+I, and right-click the volume widget.
Test Logout only when ready to leave the session; it must lock first and
terminate that session.
