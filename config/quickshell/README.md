# Quickshell Status Bar & Notification Center

A modern, native Wayland status bar, notification center, and system widget suite built using **[Quickshell](https://quickshell.outfoxxed.me/)** (Qt Quick / QML) for **Hyprland** on NixOS.

Designed around the **Catppuccin Mocha** color palette with a 3-section layout, native floating popups, and full hardware & notification integration.

---

## 🌟 Key Features

### 1. True 3-Section Layout
- **Left**: Hyprland Workspaces with debounced mouse-wheel switching and active window title.
- **Center (Mathematically Centered)**: Notification center pill (with unread count & DND status), clickable Date pill (opens monthly Calendar), and Weather forecast pill.
- **Right**: System status indicators and interactive dropdown menus separated by symmetrical dividers.

### 2. Native Dropdown Popup Engine
- Every widget popup floats **8px below the bar** with clean rounded cards (`cardRadius: 12px`, subtle 1px border).
- Powered natively by Quickshell's `PopupAnchor` (`anchor.item: iconContainer`), providing instant, lag-free anchoring without manual coordinate mapping.
- Automatic Hyprland window focus grabbing (`HyprlandFocusGrab`) with click-outside dismissal.

### 3. Native Desktop Notification System

- Clicking a toast or history entry invokes the app's default notification action
  and explicitly focuses its most recently used matching window after the popup
  releases focus. Without an action or open window, it launches the supplied
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
  - **Idle Inhibitor (`IdleIndicatorWidget.qml`)**: Toggle `hypridle` inhibition on/off.
  - **Power Menu (`PowerWidget.qml`)**: Fast access to Lock, Suspend, Reboot, and Shutdown.

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
├── NotifManager.qml                  # NotificationServer singleton & history
├── qmldir                            # QML module & singleton registration
├── components/
│   ├── DropdownWidget.qml            # Base component for right-side dropdowns
│   ├── NotificationToasts.qml        # Floating notification banners (top-right)
│   ├── CenterInfo.qml                # Center Notifications, Calendar & Weather
│   ├── WorkspaceBar.qml              # Hyprland workspace switcher with debounced scroll
│   ├── WindowInfo.qml                # Active window title
│   ├── CpuWidget.qml                 # Top CPU processes dropdown
│   ├── MemoryWidget.qml              # Top RAM processes dropdown
│   ├── VolumeWidget.qml              # WirePlumber volume & sink manager
│   ├── BatteryWidget.qml             # Battery status & power profile switcher
│   ├── WifiWidget.qml                # Network speed & Wi-Fi dropdown
│   ├── BluetoothWidget.qml           # Bluetooth device manager
│   ├── CameraIndicatorWidget.qml     # Active camera / recording indicator
│   ├── IdleIndicatorWidget.qml       # Hypridle inhibitor toggle
│   ├── Clock.qml                     # Clock widget
│   ├── PowerWidget.qml               # Lock / Suspend / Reboot / Poweroff menu
│   └── Separator.qml                 # Symmetrical vertical divider
└── scripts/
    └── weather.py                    # Standalone weather fetcher (wttr.in)
```

---

## 🔧 System Requirements

The Nix `quickshell-session` launcher resolves the live Hyprland instance on the
current Wayland display before starting the bar. Workspace state supports both
the older numeric `id` and Hyprland 0.56's `address` format, with IPC event updates
and a one-second refresh fallback. Workspace clicks use `hyprctl eval` for Lua
dispatchers, including empty workspaces and workspace 10.

Screenshot shortcuts are **Print** for an area and **Super+Print** for the full
desktop. Captures are saved in `~/Pictures/Screenshots` and copied to the
clipboard. Escape cancels area selection. Home Manager embeds the packaged
helper path in `hyprland.lua`, so the shortcuts do not depend on the session PATH.

Volume, speaker/microphone mute, and brightness keys show a short indicator at
the bottom of the focused screen. Brightness targets that screen's laptop
backlight or external monitor via DDC, and displays the value read back from the
hardware. The indicator does not take keyboard focus or intercept clicks.

- **Compositor**: Hyprland
- **Shell**: Quickshell (`quickshell`)
- **Tools**:
  - `wireplumber` / `wpctl` (Audio)
  - `power-profiles-daemon` / `powerprofilesctl` (Power management)
  - `bluez` / `bluetoothctl` (Bluetooth)
  - `networkmanager` / `nmcli` (Wi-Fi)
  - `python3` with `urllib` (Weather)
  - `jq` (JSON parsing)
