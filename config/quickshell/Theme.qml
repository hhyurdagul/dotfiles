pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: themeRoot

    // -------------------------------------------------------------
    // Dynamic Dark/Light Mode State
    // -------------------------------------------------------------
    property bool isDark: true
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
        || (Quickshell.env("HOME") + "/.local/state")

    function syncThemeMode() {
        var mode = _themeFile.text().trim()
        themeRoot.isDark = mode !== "light"
    }

    property var _themeFile: FileView {
        path: themeRoot.stateHome + "/theme/mode"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: themeRoot.syncThemeMode()
        Component.onCompleted: themeRoot.syncThemeMode()
    }

    // -------------------------------------------------------------
    // Base Surface & Text Colors (Catppuccin Mocha vs Latte)
    // -------------------------------------------------------------
    readonly property color colBg: isDark ? "#1e1e2e" : "#eff1f5"
    readonly property color colBgSurface: isDark ? "#313244" : "#e6e9ef"
    readonly property color colBgCrust: isDark ? "#11111b" : "#dce0e8"
    readonly property color colFg: isDark ? "#cdd6f4" : "#4c4f69"
    readonly property color colFgDim: isDark ? "#a6adc8" : "#6c6f85"
    readonly property color colMuted: isDark ? "#6c7086" : "#9ca0b0"
    readonly property color colBorder: isDark ? "#45475a" : "#bcc0cc"

    // -------------------------------------------------------------
    // Unified Accent Palette (Catppuccin Mocha vs Latte)
    // -------------------------------------------------------------
    readonly property color colGreen: isDark ? "#a6e3a1" : "#40a02b"
    readonly property color colRed: isDark ? "#f38ba8" : "#d20f39"
    readonly property color colYellow: isDark ? "#f9e2af" : "#df8e1d"
    readonly property color colOrange: isDark ? "#fab387" : "#fe640b"
    readonly property color colPeach: isDark ? "#fe640b" : "#fe640b"
    readonly property color colBlue: isDark ? "#89b4fa" : "#1e66f5"
    readonly property color colLavender: isDark ? "#b4befe" : "#7287fd"
    readonly property color colSapphire: isDark ? "#74c7ec" : "#209fb5"
    readonly property color colMauve: isDark ? "#cba6f7" : "#8839ef"
    readonly property color colPink: isDark ? "#f5c2e7" : "#ea76cb"
    readonly property color colTeal: isDark ? "#94e2d5" : "#179299"

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
    readonly property color colWorkspaceActive: isDark ? "#cdd6f4" : "#4c4f69"
    readonly property color colWorkspaceInactive: colMuted
    readonly property color colCamera: colRed
    readonly property color colIdle: colYellow

    // -------------------------------------------------------------
    // Popup & Card Layout Styling (Easily tweakable from here!)
    // -------------------------------------------------------------
    readonly property int popupTopMargin: 8
    readonly property int popupPadding: 12
    readonly property int cardRadius: 12
    readonly property int itemRadius: 6
    readonly property int compactRadius: 5
    readonly property int mediumRadius: 8
    readonly property int tinyRadius: 4
    readonly property color cardBorderColor: Qt.rgba(colFg.r, colFg.g, colFg.b, isDark ? 0.10 : 0.12)
    readonly property int cardBorderWidth: 1
    readonly property color colHover: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.10)
    readonly property color colHoverStrong: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.15)
    readonly property color colSelected: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.12)
    readonly property color colSurface: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.05)
    readonly property color colSurfaceFaint: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.03)
    readonly property color colDivider: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.08)
    readonly property color colDangerSurface: Qt.rgba(colRed.r, colRed.g, colRed.b, 0.20)
    readonly property color colCpuSurface: Qt.rgba(colCpu.r, colCpu.g, colCpu.b, 0.15)
    readonly property color colMemSurface: Qt.rgba(colMem.r, colMem.g, colMem.b, 0.15)
    readonly property int densePadding: 6
    readonly property int itemPadding: 8
    readonly property int toastPadding: 10
    readonly property int calendarPadding: 14
    readonly property int weatherPadding: 16
    readonly property int osdBottomMargin: 80
    readonly property int osdWidth: 280
    readonly property int osdHeight: 80

    // -------------------------------------------------------------
    // Typography
    // -------------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeLarge: 14
}
