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
    // Base Surface & Text Colors (Ember dark vs Dust light)
    // Taken from config/wallpapers: dark is charcoal smoke with copper
    // sparks, light is sand and cream dust with an amber glow.
    // -------------------------------------------------------------
    readonly property color colBg: isDark ? "#1a1715" : "#f5ede3"
    readonly property color colBgCrust: isDark ? "#12100f" : "#e7dccd"
    readonly property color colFg: isDark ? "#ebdfd2" : "#3a302a"
    readonly property color colFgDim: isDark ? "#bcae9f" : "#5e5249"
    readonly property color colMuted: isDark ? "#7d6f64" : "#8f8173"

    // -------------------------------------------------------------
    // Unified Accent Palette (Ember vs Dust)
    // Warm, desaturated hues; blue and teal stay cool for contrast with the
    // warm surfaces. Every accent reads at >= 4.5:1 on colBg.
    // -------------------------------------------------------------
    readonly property color colGreen: isDark ? "#b3bd85" : "#5b7429"
    readonly property color colRed: isDark ? "#e57a6a" : "#b23a2c"
    readonly property color colYellow: isDark ? "#ecc27a" : "#8a5f0a"
    readonly property color colOrange: isDark ? "#e8955e" : "#b0521a"
    readonly property color colBlue: isDark ? "#93acc0" : "#3c6585"
    readonly property color colSapphire: isDark ? "#84b3bc" : "#2b7383"
    readonly property color colMauve: isDark ? "#c9a2a8" : "#84506a"
    readonly property color colPink: isDark ? "#dba08c" : "#a14f4c"
    readonly property color colTeal: isDark ? "#95bfae" : "#2d7565"

    // -------------------------------------------------------------
    // Semantic Component Color Bindings
    // -------------------------------------------------------------
    readonly property color colClock: colYellow
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
    // The active workspace glows like the wallpapers' embers.
    readonly property color colWorkspaceActive: colOrange
    readonly property color colCamera: colRed
    readonly property color colDictation: colPink
    readonly property color colMic: colOrange
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
    readonly property int dictationBottomMargin: 40
    readonly property int dictationWidth: 240
    readonly property int dictationHeight: 44

    // -------------------------------------------------------------
    // Typography
    // -------------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeLarge: 14
}
