# Quickshell Status Bar & Notification Center

A modern, native Wayland status bar, notification center, and system widget suite built using **[Quickshell](https://quickshell.outfoxxed.me/)** (Qt Quick / QML) for **Niri**, with a selectable **Hyprland fallback**, on NixOS.

Designed around the **Catppuccin Mocha** color palette with a 3-section layout, native floating popups, and full hardware & notification integration.

---

## 🌟 Key Features

### 1. True 3-Section Layout
- **Left**: Named Niri workspaces (or Hyprland workspaces), debounced mouse-wheel switching, app icons, and the active window title.
- **Center (Mathematically Centered)**: Notification center pill (with unread count & DND status), clickable Date pill (opens monthly Calendar), and Weather forecast pill.
- **Right**: System status indicators and interactive dropdown menus separated by symmetrical dividers.
- **Right, immediately after the tray**: Clipboard history. Search, copy, delete, and confirmed clear of text and image entries captured by `cliphist`.

### 2. Native Dropdown Popup Engine
- Every widget popup floats **8px below the bar** with clean rounded cards (`cardRadius: 12px`, subtle 1px border).
- Powered natively by Quickshell's `PopupAnchor` (`anchor.item: iconContainer`), providing instant, lag-free anchoring without manual coordinate mapping.
- Native Wayland `PopupWindow.grabFocus` provides keyboard focus and click-outside dismissal on both compositors; changing application/workspace also dismisses open menus.

### 3. Native Desktop Notification System

- Clicking a toast or history entry invokes the app's default notification action
  and explicitly focuses its most recently used matching window after the popup
  releases focus (`app_id` and integer window IDs on Niri; window classes and addresses on Hyprland).
  Without an action or open window, it launches the supplied
  desktop entry. Codex notifications map to the Paseo agent window in this setup.
  Notifications remain tracked while in history so their actions stay usable.
  Apps must supply a default action or a recognizable app name/desktop entry.
- **Built-in Notification Server (`NotifManager.qml`)**: Replaces external daemons like SwayNC or Dunst.
- **Floating Toasts (`NotificationToasts.qml`)**: Real-time notification banners in the top-right corner with 5-second auto-dismiss.
- **Do Not Disturb (DND)**:
  - **Left Click** on center bell: Opens notification history dropdown with 1-click dismissal.
  - **Right Click** on center bell: Toggles Do Not Disturb. When DND is active, toasts are suppressed while notifications silently accumulate in history.

### 4. Interactive Hardware & System Dropdowns
- **CPU (`CpuWidget.qml`)**: Live top 10 CPU-consuming processes (PID, Name, CPU%) with instant refresh and `btop` terminal shortcut.
- **Memory (`MemoryWidget.qml`)**: Live RAM usage summary (Used / Total GB) and top memory-consuming processes.
- **Volume (`VolumeWidget.qml`)**:
  - Scroll wheel: **±5% volume step**.
  - `Shift` + Scroll: **±1% fine-tuning**.
  - Dynamic audio glyphs (Headphones `󰋋`, Bluetooth `󰂰`, Speaker `󰕾`, Mute `󰖁`).
  - Right-click launcher for `pavucontrol` / audio mixer.
- **Battery & Power Profile (`BatteryWidget.qml`)**:
  - Unified battery indicator reading directly from kernel sysfs (`/sys/class/power_supply/`).
  - Integrated 1-click power profile switcher (`Performance`, `Balanced`, `Power Saver` via `powerprofilesctl`).
- **Network & Wi-Fi (`WifiWidget.qml`)**: Live upload/download throughput speed and interactive network list.
- **Bluetooth (`BluetoothWidget.qml`)**: Toggle power, scan for 30 seconds, and pair/connect headphones. Live BlueZ state tracks every connected device. Connected devices that report a battery level show a live percentage beside their name, with warning colors at 30% and 15%; the indicator is hidden when the level is unavailable. Repeated names are grouped with the connected entry first; **Show all entries** exposes individual saved addresses. The popup stays open to show progress and errors. Pairing uses a temporary `NoInputNoOutput` agent for devices such as headphones; devices requiring a PIN or passkey need a Bluetooth manager with an interactive pairing agent.
- **System Indicators**:
  - **Camera (`CameraIndicatorWidget.qml`)**: Red pill with `REC` badge when `/dev/video*` is actively recording.
  - **Microphone (`MicIndicatorWidget.qml`)**: Orange mic icon while any app captures from an input device (dictation, calls, recordings); sink monitors don't count.
  - **Idle Inhibitor (`IdleIndicatorWidget.qml`)**: Toggle `hypridle` inhibition on/off.
  - **Power Menu (`PowerWidget.qml`)**: Lock, Suspend, Logout, Reboot, and Shutdown. Logout uses `session-exit`, which locks before leaving the selected compositor session.

---

## 🎨 Theme & Customization

All visual styles, colors, margins, radiuses, and fonts are centralized in **[`Theme.qml`](./Theme.qml)**.

```qml
// Theme.qml highlights
property color colBg: "#1e1e2e"           // Mocha base background
property color colGreen: "#a6e3a1"        // Unified green (Battery, Volume, BT, RAM)
property color colRed: "#f38ba8"          // Red (Recording, Critical, Poweroff)
property color colYellow: "#f9e2af"       // Yellow (Notifications, Idle)
property color colBlue: "#89b4fa"         // Blue (CPU, Bluetooth)
property color colPink: "#f5c2e7"         // Pink (Network)
property int popupTopMargin: 8            // Floating gap between top bar and menus
property int cardRadius: 12               // Corner radius for all popups and toasts
property string fontFamily: "JetBrainsMono Nerd Font"
```

To tweak any aspect of the UI, edit `Theme.qml`. Direct edits to the running configuration hot-reload. With the Home Manager setup, rebuild to install the changes, then run `systemctl --user restart quickshell` to load the new Nix store files; replacing the configuration symlinks does not reliably trigger hot-reload.

---

## 📁 Directory Structure

```
config/quickshell/
├── shell.qml                         # Root panel window & 3-section layout
├── Theme.qml                         # Global Catppuccin Mocha theme singleton
├── Compositor.qml                    # Shared Niri IPC / Hyprland snapshot backend
├── NotifManager.qml                  # NotificationServer singleton & history
├── qmldir                            # QML module & singleton registration
├── Dictation.qml                     # Handy recording state singleton (PipeWire)
├── components/
│   ├── DropdownWidget.qml            # Base component for right-side dropdowns
│   ├── NotificationToasts.qml        # Floating notification banners (top-right)
│   ├── CenterInfo.qml                # Center Notifications, Calendar & Weather
│   ├── WorkspaceBar.qml              # Compositor-neutral switcher with debounced scroll
│   ├── WindowInfo.qml                # Active window title
│   ├── CpuWidget.qml                 # Top CPU processes dropdown
│   ├── MemoryWidget.qml              # Top RAM processes dropdown
│   ├── VolumeWidget.qml              # WirePlumber volume & sink manager
│   ├── BatteryWidget.qml             # Battery status & power profile switcher
│   ├── WifiWidget.qml                # Network speed & Wi-Fi dropdown
│   ├── BluetoothWidget.qml           # Bluetooth device manager
│   ├── CameraIndicatorWidget.qml     # Active camera / recording indicator
│   ├── MicIndicatorWidget.qml        # Microphone-in-use indicator
│   ├── DictationOverlay.qml          # Bottom-center card while Handy records
│   ├── IdleIndicatorWidget.qml       # Hypridle inhibitor toggle
│   ├── Clock.qml                     # Clock widget
│   ├── PowerWidget.qml               # Lock / Suspend / Reboot / Poweroff menu
│   └── Separator.qml                 # Symmetrical vertical divider
└── scripts/
    └── weather.py                    # Standalone weather fetcher (wttr.in)
```

---

## 🔧 System Requirements

`Compositor.qml` owns all compositor state; widgets do not launch their own
compositor polling processes. It detects Niri from `XDG_CURRENT_DESKTOP` or,
unless the desktop explicitly selects Hyprland, `NIRI_SOCKET`. The session launcher
must pass the selected session's `WAYLAND_DISPLAY`, desktop identity, and IPC
environment. Do not reuse stale environment variables from a previous session.

- **Niri 26.04**: Two native Unix sockets connect to `NIRI_SOCKET`: one subscribes
  to the JSON `EventStream` (including its initial complete state), the other sends
  actions. Disconnected sockets are reconnected; Niri state is not polled.
  Workspace buttons always show names **1–10**, regardless of their monitor-local
  indices. Focus uses an explicit IPC
  `Name` reference: the CLI argument `focus-workspace 6` would instead mean index
  6 on the current output. Wheel navigation moves through names 1–10, clamped at
  the ends, crossing outputs where the configured workspace lives. Unnamed dynamic
  Niri workspaces are not numbered in the bar.
- **Hyprland fallback**: One shared one-second `hyprctl --batch`/`jq` snapshot
  refreshes workspaces, windows, the active title, and focused output. State may
  therefore lag by up to one second (unlike the previous per-widget event hooks).
  Workspace actions request an additional short delayed refresh. Both numeric
  workspace IDs and Hyprland 0.56 workspace addresses are accepted; clicks still
  use Lua `hyprctl eval`, and wheel switching retains `e-1`/`e+1` semantics.
  No `Quickshell.Hyprland` imports or focus-grab objects are loaded in either session.
- **Popups**: Require Quickshell **0.3.0 or newer**, specifically
  [`PopupWindow.grabFocus`](https://quickshell.org/docs/v0.3.0/types/Quickshell/PopupWindow/).
  Native Wayland dismissal replaces `HyprlandFocusGrab`; an outside click dismisses
  the popup rather than leaving it open for custom handling. As with native popup
  grabs generally, clicking another control may first dismiss the existing popup.
- **Notifications and overlays**: Notification default actions, history, DND,
  app matching (including the Codex/Paseo mapping), weather, hardware dropdowns,
  and dictation remain compositor-independent. Dictation follows the backend's
  focused output. OSD uses the helper-supplied output, or the backend's focused
  output when none is supplied; an unavailable output falls back to the first screen.
- **Logout**: Calls the packaged `session-exit` helper, not `uwsm` directly.
  Niri uses native session exit; UWSM remains confined to Hyprland fallback.

Screenshots are compositor shortcuts rather than Quickshell widgets. Niri uses
its native screenshot UI for **Print** and focused-screen capture for
**Super+Print**; Hyprland retains its screenshot helper. See the root README for
the complete shortcut and screenshot-storage differences.

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

- **Compositor**: Niri 26.04 (default), or the configured Hyprland Lua fallback
- **Shell**: Quickshell (`quickshell`) **>= 0.3.0**, with Wayland and Io modules
- **Session helpers on PATH**: `session-exit`, `lock-screen`, `idle-toggle`, `desktop-control`, and `handy` for dictation cancellation
- **IPC environment**: Reachable `NIRI_SOCKET` on Niri; the selected `HYPRLAND_INSTANCE_SIGNATURE` on Hyprland
- **Tools**:
  - `wireplumber` / `wpctl` (Audio)
  - `power-profiles-daemon` / `powerprofilesctl` (Power management)
  - `bluez` / `bluetoothctl` (Bluetooth)
  - `networkmanager` / `nmcli` (Wi-Fi)
  - `python3` with `urllib` (Weather)
  - `jq` and `hyprctl` (Hyprland backend only)
  - `systemctl` (power/session services)

## Verification after integration

Integration smoke: the full shell loaded in a nested Niri 26.04 session on
Quickshell 0.3.0 and rendered its bar and window. Native named-workspace actions,
window focus/title updates, keyboard switching, display
power commands, and screenshot capture were exercised. The shared Hyprland
backend was checked against live compositor state. Both generated themes passed
Niri validation; the NixOS build, Nix formatting, statix, and deadnix passed.
Two longer-lived nested instances later stopped answering IPC; short probes of
both the empty configuration and the migrated full shell accepted screenshots
and exited natively with compositor status 0. Cause of the nested stall is not
established; this is not proof of physical-session stability. The native quit
CLI can report EOF when the compositor exits before writing its reply.
Physical monitor modes/gestures, notification delivery (the host owns the D-Bus
name), popup interaction, hardware controls, and full session logout still need
checking after activation in a real selected session:

```sh
quickshell --version
systemctl --user restart quickshell
journalctl --user -u quickshell -b --no-pager
# In Niri: inspect the same native state/event protocol used by the backend.
niri msg --json workspaces
niri msg --json windows
niri msg --json focused-output
niri msg --json event-stream
# In the selectable Hyprland fallback:
hyprctl -j --batch 'activeworkspace;workspaces;clients;activewindow;monitors'
```

Stop the foreground event stream with Ctrl+C. Check workspace buttons 1, 6, and
10 on their configured outputs, wheel boundaries,
window-title changes, notification clicks (`notify-send -a kitty "Focus test"`
with a Kitty window open), and outside-click/Escape dismissal of every menu.
While Handy records, change focused outputs and cancel from the dictation card;
exercise volume/brightness keys and confirm OSD placement. Repeat menu,
workspace, title, notification and overlay checks in Hyprland. Test Logout only
when ready to leave the session; it must lock first and terminate that session.
