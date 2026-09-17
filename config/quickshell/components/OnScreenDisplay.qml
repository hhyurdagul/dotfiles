import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
    id: osd
    property string kind: "volume"
    property int value: 0
    property bool muted: false
    property string screenName: ""
    property string message: ""

    IpcHandler {
        target: "osd"
        function display(kind: string, value: int, muted: bool, screenName: string, message: string): void {
            osd.kind = kind
            osd.value = value
            osd.muted = muted
            osd.screenName = screenName
            osd.message = message
            hideTimer.restart()
        }
    }

    Timer { id: hideTimer; interval: 1600 }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: hideTimer.running && (osd.screenName === modelData.name
                || (!Quickshell.screens.some(s => s.name === osd.screenName) && modelData === Quickshell.screens[0]))
            anchors.bottom: true
            margins.bottom: Theme.osdBottomMargin
            implicitWidth: Theme.osdWidth
            implicitHeight: Theme.osdHeight
            exclusiveZone: 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.namespace: "quickshell-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                radius: Theme.cardRadius
                color: Theme.colBg
                border.color: Theme.cardBorderColor
                border.width: Theme.cardBorderWidth
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.popupPadding
                    spacing: Theme.itemPadding
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.itemPadding
                        Text {
                            text: osd.kind === "brightness" ? "󰃠" : osd.kind === "microphone"
                                ? (osd.muted ? "󰍭" : "󰍬") : (osd.muted ? "󰖁" : "󰕾")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge + 6
                            color: osd.kind === "brightness" ? Theme.colYellow : Theme.colVol
                        }
                        Text {
                            Layout.fillWidth: true
                            text: osd.message || (osd.kind === "brightness" ? "Brightness" : osd.kind === "microphone" ? "Microphone" : "Volume")
                            elide: Text.ElideRight
                            color: Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            text: osd.value < 0 ? "" : osd.muted ? "Muted" : osd.value + "%"
                            color: Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.densePadding
                        radius: Theme.tinyRadius
                        visible: osd.value >= 0
                        color: Theme.colSurface
                        Rectangle {
                            height: parent.height
                            width: parent.width * (osd.muted ? 0 : Math.max(0, Math.min(100, osd.value)) / 100)
                            radius: Theme.tinyRadius
                            color: osd.kind === "brightness" ? Theme.colYellow : Theme.colVol
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }
                }
            }
        }
    }
}
