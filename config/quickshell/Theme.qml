pragma Singleton
import QtQuick

QtObject {
    // -------------------------------------------------------------
    // Base Surface & Text Colors (Catppuccin Mocha)
    // -------------------------------------------------------------
    readonly property color colBg: "#1e1e2e"           // Base background
    readonly property color colBgSurface: "#313244"    // Elevated surface (hover, cards)
    readonly property color colBgCrust: "#11111b"      // Darkest background
    readonly property color colFg: "#cdd6f4"           // Primary text (Text)
    readonly property color colFgDim: "#a6adc8"        // Secondary text (Subtext0)
    readonly property color colMuted: "#6c7086"        // Muted / Overlay0 / Separators
    readonly property color colBorder: "#45475a"       // Surface2 border

    // -------------------------------------------------------------
    // Unified Accent Palette (Catppuccin Mocha)
    // -------------------------------------------------------------
    readonly property color colGreen: "#a6e3a1"        // Unified clean Green
    readonly property color colRed: "#f38ba8"          // Red (Critical, Recording, Shutdown, Error)
    readonly property color colYellow: "#f9e2af"       // Yellow / Gold (Warning, Notifs)
    readonly property color colOrange: "#fab387"       // Orange (Clock, Reboot)
    readonly property color colPeach: "#fe640b"        // Peach
    readonly property color colBlue: "#89b4fa"         // Blue (CPU, Bluetooth, Info)
    readonly property color colLavender: "#b4befe"     // Lavender
    readonly property color colSapphire: "#74c7ec"     // Sapphire (Cold Weather)
    readonly property color colMauve: "#cba6f7"        // Mauve / Purple (Window title)
    readonly property color colPink: "#f5c2e7"         // Pink / Flamingo (Network, Wifi)
    readonly property color colTeal: "#94e2d5"         // Teal (Memory)

    // -------------------------------------------------------------
    // Semantic Component Color Bindings
    // -------------------------------------------------------------
    readonly property color colClock: colOrange
    readonly property color colCpu: colBlue
    readonly property color colMem: colTeal
    readonly property color colVol: colGreen
    readonly property color colBattery: colGreen
    readonly property color colBatteryLow: colRed
    readonly property color colBatteryWarn: colYellow
    readonly property color colBatteryCharging: colGreen
    readonly property color colNetwork: colPink
    readonly property color colBluetooth: colBlue
    readonly property color colBluetoothConnected: colGreen
    readonly property color colWindow: colMauve
    readonly property color colWorkspaceActive: "#cdd6f4"
    readonly property color colWorkspaceInactive: colMuted
    readonly property color colCamera: colRed
    readonly property color colIdle: colYellow

    // -------------------------------------------------------------
    // Popup & Card Layout Styling (Easily tweakable from here!)
    // -------------------------------------------------------------
    readonly property int popupTopMargin: 8            // Gap between top bar and all floating menus
    readonly property int cardRadius: 12               // Corner radius for all popups
    readonly property color cardBorderColor: Qt.rgba(255, 255, 255, 0.1)
    readonly property int cardBorderWidth: 1

    // -------------------------------------------------------------
    // Typography
    // -------------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeLarge: 14
}
