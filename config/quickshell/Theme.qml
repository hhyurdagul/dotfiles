pragma Singleton
import QtQuick

QtObject {
    // Theme colors - Chroma Glow style (matching waybar)
    readonly property color colBg: "#1e1e2e"           // Dark background (Catppuccin Mocha base)
    readonly property color colBgTransparent: "transparent"  // Fully transparent background
    readonly property color colFg: "#cdd6f4"           // Light text
    readonly property color colMuted: "#606060"        // Muted/separator color
    readonly property color colClock: "#fe640b"        // Orange for clock
    readonly property color colCpu: "#7287fd"          // Blue for CPU
    readonly property color colMem: "#40a02b"          // Green for memory
    readonly property color colDisk: "#8b4513"         // Brown for disk
    readonly property color colVol: "#40a02b"          // Green for volume
    readonly property color colNetwork: "#dd7878"      // Pink for network
    readonly property color colBluetooth: "#89b4fa"    // Blue for bluetooth
    readonly property color colSlack: "#611f69"        // Slack purple
    readonly property color colWhatsapp: "#25d366"     // WhatsApp green
    readonly property color colWorkspaceActive: "#D3D3D3"  // Light gray for active workspace
    readonly property color colWorkspaceInactive: "grey"   // Grey for inactive
    readonly property color colWindow: "#cba6f7"       // Mauve for window title
    readonly property color colKernel: "#f38ba8"       // Red/pink for kernel

    // Font
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
}
